#!/usr/bin/env python3
"""
Report whether GuardDuty, Security Hub V2, Amazon Inspector, or Security Hub CSPM
(both the classic v1 hub and the v2 central-configuration policy layer) are still
enabled anywhere in the organization.

Read-only sibling to wipe_guardduty.py / wipe_sechub_v2.py / wipe_sechub_cspm.py — it
checks the same surfaces those scripts tear down, but never mutates anything. Useful
after a wipe (or a `security_hub_configuration = null` / `disable_*` apply) to confirm
nothing billable was left behind.

Runs from the Organization Management (payer) account, using ROLE_NAME (default:
OrganizationAccountAccessRole) to assume into every other member account, exactly like
the wipe scripts.

Checks, per ACTIVE account x every enabled region:
  - GuardDuty:            get_detector Status == ENABLED for any detector
  - Security Hub V2:      describe_security_hub_v2() succeeds
  - Inspector:            batch_get_account_status() (self) state.status != DISABLED
  - Security Hub CSPM v1: describe_hub() succeeds (the classic/legacy hub)

Checks once, org-wide, against whichever account is registered as the Security Hub V2
delegated admin (the same admin that owns CSPM central configuration):
  - Security Hub CSPM v2: aws_securityhub_organization_configuration ConfigurationType
    == CENTRAL, and/or any configuration policy still associated (status PENDING or
    SUCCESS) to an account, OU, or root — the exact leftover state that caused the
    2026-08-15 org_kickstart_standards deletion incident
    (BUGS-FOUND/securityhub-cspm-configuration-policy-orphaned-association-2026-08-15.md).

Also reports (informational, always shown if present — these don't bill directly but
are exactly the kind of org-level leftover state Terraform can't see and won't clean
up on its own): lingering delegated-admin registrations for GuardDuty, Security Hub
(v1), Security Hub V2, and Inspector.

By default, prints ONLY what's still enabled/leftover (silent if everything is clean).
Pass --progress to also stream per-account/per-region progress as the scan runs.

Constants (edit at the top of the file if your setup differs):
  ROLE_NAME   — cross-account role assumed from the payer into each account, including
                any delegated admin. OrganizationAccountAccessRole is the org-kickstart
                default and is trusted by both the security account and every workload.
  HOME_REGION — region used for the initial describe_regions / list_accounts calls
                only; the actual status checks span every enabled region.

Exits 0 if everything is clean; 1 if anything is still enabled, leftover, or could not
be checked (assume-role failure, unexpected API error).
"""

import argparse
import logging
import sys

import boto3
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

ROLE_NAME = "OrganizationAccountAccessRole"
HOME_REGION = "us-east-1"

# Error codes that mean "this service just isn't enabled/subscribed here" across the
# various SecurityHub/GuardDuty describe/disable-style calls used below.
NOT_ENABLED_CODES = ("InvalidAccessException", "ResourceNotFoundException")


def get_enabled_regions(session):
    ec2 = session.client("ec2", region_name=HOME_REGION)
    resp = ec2.describe_regions(
        AllRegions=False,
        Filters=[{"Name": "opt-in-status", "Values": ["opt-in-not-required", "opted-in"]}],
    )
    return [r["RegionName"] for r in resp["Regions"]]


def get_all_accounts(session):
    orgs = session.client("organizations")
    accounts = []
    for page in orgs.get_paginator("list_accounts").paginate():
        for a in page["Accounts"]:
            if a["Status"] == "ACTIVE":
                accounts.append({"Id": a["Id"], "Name": a["Name"]})
    return accounts


def assume_role(sts, target_account_id):
    """Assume ROLE_NAME into target_account_id using an already-created STS client."""
    role_arn = f"arn:aws:iam::{target_account_id}:role/{ROLE_NAME}"
    try:
        creds = sts.assume_role(RoleArn=role_arn, RoleSessionName="status-security-services")["Credentials"]
        return {
            "aws_access_key_id": creds["AccessKeyId"],
            "aws_secret_access_key": creds["SecretAccessKey"],
            "aws_session_token": creds["SessionToken"],
        }
    except ClientError as e:
        logger.error(f"assume_role({target_account_id}) failed: {e}")
        return None


# --- Delegated-admin registration checks (informational; org-wide, per region) -------

def find_admins(payer_session, regions, service, list_call, id_key, feature=None):
    """
    Generic per-region delegated-admin scan. Returns {account_id: [regions]}.
    `list_call` is a zero-arg-or-Feature-kwarg callable bound to a region-specific client.
    """
    found = {}
    for region in regions:
        client = payer_session.client(service, region_name=region)
        try:
            kwargs = {"Feature": feature} if feature else {}
            resp = getattr(client, list_call)(**kwargs)
            key = "AdminAccounts" if "AdminAccounts" in resp else "delegatedAdminAccounts"
            for a in resp.get(key, []):
                found.setdefault(a[id_key], []).append(region)
        except ClientError as e:
            logger.warning(f"[{region}] {service} {list_call} failed: {e}")
    return found


# --- Per-account x per-region checks --------------------------------------------------

def check_guardduty(client, name, region, progress):
    try:
        detector_ids = client.list_detectors().get("DetectorIds", [])
    except ClientError as e:
        return [("ERROR", f"list_detectors failed: {e}")]

    if not detector_ids:
        if progress:
            logger.info(f"[{region}] {name}: GuardDuty — no detector")
        return []

    findings = []
    for detector_id in detector_ids:
        try:
            status = client.get_detector(DetectorId=detector_id)["Status"]
        except ClientError as e:
            findings.append(("ERROR", f"get_detector({detector_id}) failed: {e}"))
            continue
        if status == "ENABLED":
            findings.append(("ENABLED", f"detector {detector_id} is ENABLED"))
        elif progress:
            logger.info(f"[{region}] {name}: GuardDuty detector {detector_id} is {status}")
    return findings


def check_sechub_v2(client, name, region, progress):
    try:
        client.describe_security_hub_v2()
        return [("ENABLED", "Security Hub V2 hub is enabled")]
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in NOT_ENABLED_CODES:
            if progress:
                logger.info(f"[{region}] {name}: Security Hub V2 — not enabled")
            return []
        return [("ERROR", f"describe_security_hub_v2 failed: {e}")]


def check_sechub_v1(client, name, region, progress):
    try:
        client.describe_hub()
        return [("ENABLED", "Security Hub (v1/CSPM classic) hub is enabled")]
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in NOT_ENABLED_CODES:
            if progress:
                logger.info(f"[{region}] {name}: Security Hub v1 — not enabled")
            return []
        return [("ERROR", f"describe_hub failed: {e}")]


def check_inspector(client, name, region, progress):
    try:
        resp = client.batch_get_account_status()
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code == "AccessDeniedException":
            if progress:
                logger.info(f"[{region}] {name}: Inspector — not enrolled")
            return []
        return [("ERROR", f"batch_get_account_status failed: {e}")]

    accounts = resp.get("accounts", [])
    if not accounts:
        if progress:
            logger.info(f"[{region}] {name}: Inspector — no status returned (not enrolled)")
        return []

    status = accounts[0]["state"]["status"]
    if status == "DISABLED":
        if progress:
            logger.info(f"[{region}] {name}: Inspector — DISABLED")
        return []
    return [("ENABLED", f"Inspector account status is {status}")]


PER_ACCOUNT_CHECKS = [
    ("GuardDuty", "guardduty", check_guardduty),
    ("SecHub2", "securityhub", check_sechub_v2),
    ("Inspector", "inspector2", check_inspector),
    ("SecHub CSPM (v1)", "securityhub", check_sechub_v1),
]


# --- Org-wide Security Hub CSPM v2 (central configuration) check ---------------------

def check_cspm_v2_central_config(admin_session, regions, progress):
    """
    From the Security Hub V2 delegated admin, per region:
      - describe_organization_configuration: is central config still CENTRAL?
      - list_configuration_policies + list_configuration_policy_associations: any
        policy still associated (PENDING/SUCCESS) to an account, OU, or root?
    """
    findings = []
    for region in regions:
        sh = admin_session.client("securityhub", region_name=region)

        try:
            oc = sh.describe_organization_configuration()["OrganizationConfiguration"]
            if oc.get("ConfigurationType") == "CENTRAL":
                findings.append(("ENABLED", f"[{region}] central configuration is still CENTRAL"))
            elif progress:
                logger.info(f"[{region}] CSPM v2: central config is {oc.get('ConfigurationType')}")
        except ClientError as e:
            code = e.response["Error"]["Code"]
            if code not in NOT_ENABLED_CODES:
                findings.append(("ERROR", f"[{region}] describe_organization_configuration failed: {e}"))

        try:
            policies = sh.list_configuration_policies().get("ConfigurationPolicySummaries", [])
        except ClientError as e:
            code = e.response["Error"]["Code"]
            if code not in NOT_ENABLED_CODES:
                findings.append(("ERROR", f"[{region}] list_configuration_policies failed: {e}"))
            policies = []

        for policy in policies:
            pid, pname = policy["Id"], policy["Name"]
            if progress:
                logger.info(f"[{region}] CSPM v2: policy {pname} ({pid}) exists — checking associations")
            try:
                assocs = sh.list_configuration_policy_associations(
                    Filters={"ConfigurationPolicyId": pid}
                ).get("ConfigurationPolicyAssociationSummaries", [])
            except ClientError as e:
                findings.append(("ERROR", f"[{region}] list_configuration_policy_associations({pid}) failed: {e}"))
                continue

            for a in assocs:
                if a["AssociationStatus"] in ("PENDING", "SUCCESS"):
                    findings.append((
                        "ENABLED",
                        f"[{region}] policy '{pname}' ({pid}) associated to "
                        f"{a['TargetType']} {a['TargetId']} ({a['AssociationType']}, "
                        f"status {a['AssociationStatus']})",
                    ))
                elif progress:
                    logger.info(
                        f"[{region}] CSPM v2: policy '{pname}' -> {a['TargetType']} "
                        f"{a['TargetId']} status {a['AssociationStatus']} (not counted)"
                    )
    return findings


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Report whether GuardDuty, Security Hub V2, Inspector, or Security Hub "
            "CSPM (v1 and v2 central config) are enabled anywhere in the org. "
            "Read-only — prints only what's still enabled unless --progress is set."
        ),
    )
    parser.add_argument(
        "--progress",
        action="store_true",
        help="Also stream per-account/per-region progress while scanning.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    if not args.progress:
        logger.setLevel(logging.WARNING)

    payer_session = boto3.Session()
    sts = payer_session.client("sts")
    payer_id = sts.get_caller_identity()["Account"]
    logger.info(f"Payer: {payer_id}")

    regions = get_enabled_regions(payer_session)
    logger.info(f"Enabled regions ({len(regions)}): {regions}")

    accounts = get_all_accounts(payer_session)
    logger.info(f"Active org accounts: {len(accounts)}")

    findings = []  # list of (severity, label) where label already includes account/region context
    had_error = False

    # --- Delegated-admin registration leftovers (informational, org-wide) ---
    admin_checks = [
        ("GuardDuty admin", "guardduty", "list_organization_admin_accounts", "AdminAccountId", None),
        ("Security Hub v1 admin", "securityhub", "list_organization_admin_accounts", "AccountId", "SecurityHub"),
        ("Security Hub V2 / CSPM admin", "securityhub", "list_organization_admin_accounts", "AccountId", "SecurityHubV2"),
        ("Inspector admin", "inspector2", "list_delegated_admin_accounts", "accountId", None),
    ]
    v2_admin_id = None
    for label, service, call, id_key, feature in admin_checks:
        found = find_admins(payer_session, regions, service, call, id_key, feature)
        for admin_id, admin_regions in found.items():
            findings.append((
                "ENABLED",
                f"{label}: {admin_id} still registered as delegated admin "
                f"(regions: {', '.join(admin_regions)})",
            ))
            if label == "Security Hub V2 / CSPM admin":
                v2_admin_id = admin_id

    # --- Security Hub CSPM v2 (central config) — checked once, from the delegated admin ---
    if v2_admin_id:
        admin_creds = assume_role(sts, v2_admin_id)
        if admin_creds is None:
            findings.append(("ERROR", f"Could not assume {ROLE_NAME} in CSPM v2 admin {v2_admin_id} to check central config"))
            had_error = True
        else:
            admin_session = boto3.Session(**admin_creds)
            findings.extend(check_cspm_v2_central_config(admin_session, regions, args.progress))
    elif args.progress:
        logger.info("No Security Hub V2 / CSPM delegated admin registered — skipping central-config check")

    # --- Per-account x per-region checks ---
    for acct in accounts:
        aid, name = acct["Id"], acct["Name"]
        if args.progress:
            logger.info(f"\n--- {name} ({aid}) ---")

        if aid == payer_id:
            def factory(service, region, s=payer_session):
                return s.client(service, region_name=region)
        else:
            creds = assume_role(sts, aid)
            if creds is None:
                findings.append(("ERROR", f"{name} ({aid}): unable to assume {ROLE_NAME} — not checked"))
                had_error = True
                continue

            def factory(service, region, c=creds):
                return boto3.client(service, region_name=region, **c)

        for region in regions:
            for check_label, service, check_fn in PER_ACCOUNT_CHECKS:
                client = factory(service, region)
                for severity, detail in check_fn(client, name, region, args.progress):
                    findings.append((severity, f"{name} ({aid}) [{region}] {check_label}: {detail}"))
                    if severity == "ERROR":
                        had_error = True

    enabled = [f for sev, f in findings if sev == "ENABLED"]
    errors = [f for sev, f in findings if sev == "ERROR"]

    print("=" * 70)
    if not enabled and not errors:
        print(f"All clear — GuardDuty, Security Hub V2, Inspector, and Security Hub CSPM "
              f"(v1 + v2 central config) are disabled across {len(accounts)} account(s) x "
              f"{len(regions)} region(s).")
        sys.exit(0)

    if enabled:
        print(f"STILL ENABLED / LEFTOVER ({len(enabled)}):")
        for line in enabled:
            print(f"  - {line}")
    if errors:
        print(f"\nCOULD NOT CHECK ({len(errors)}):")
        for line in errors:
            print(f"  - {line}")

    sys.exit(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.error("Interrupted by user.")
        sys.exit(130)
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        sys.exit(1)
