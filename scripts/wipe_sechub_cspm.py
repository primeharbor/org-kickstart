#!/usr/bin/env python3
"""
Fully disable AWS Security Hub CSPM (v1) across the entire organization.

Runs from the Organization Management (payer) account. Handles both scenarios:

  * A current Security Hub delegated admin is registered — full teardown flow
    (disable auto-enable, disassociate + delete members, delete finding aggregator,
    then remove the delegated admin registration from the payer).
  * No current delegated admin — skip the admin steps and just scrub each account.

After the (optional) admin teardown, the script iterates every ACTIVE account in the
org, assumes OrganizationAccountAccessRole where necessary, and in every enabled region
deletes any leftover finding aggregator and then calls DisableSecurityHub.

Complements wipe_sechub_v2.py (which handles the unified Security Hub V2).

Run as the payer. Uses only the payer's credentials — the delegated admin account is
discovered via list_organization_admin_accounts and accessed by assuming ROLE_NAME
(default: OrganizationAccountAccessRole) into it, same as every other member account.

Constants (edit at the top of the file if your setup differs):
  ROLE_NAME   — cross-account role assumed from the payer into each account, including
                the delegated admin. OrganizationAccountAccessRole is the org-kickstart
                default and is trusted by both the security account and every workload.
  HOME_REGION — region used for the initial describe_regions / list_accounts calls
                only; the destructive work spans every enabled region.

Exits 0 if every operation succeeded; 1 if any errors were logged.
"""

import logging
import sys

import boto3
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

ROLE_NAME = "OrganizationAccountAccessRole"
HOME_REGION = "us-east-1"


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


def assume_role(target_account_id):
    sts = boto3.client("sts")
    role_arn = f"arn:aws:iam::{target_account_id}:role/{ROLE_NAME}"
    try:
        creds = sts.assume_role(RoleArn=role_arn, RoleSessionName="wipe-sechub-cspm")["Credentials"]
        return {
            "aws_access_key_id": creds["AccessKeyId"],
            "aws_secret_access_key": creds["SecretAccessKey"],
            "aws_session_token": creds["SessionToken"],
        }
    except ClientError as e:
        logger.error(f"assume_role({target_account_id}) failed: {e}")
        return None


def find_current_admin(payer_session, regions):
    """
    Return the account ID of the SH admin, or None.

    Security Hub delegated-admin registration is PER-REGION — you can be registered
    in some regions and not others, which is exactly what a partial teardown produces.
    We scan every enabled region and return the first admin we find. If different
    regions have different admins registered, we log a warning; the script assumes
    a single admin org-wide.
    """
    found = {}
    for region in regions:
        sh = payer_session.client("securityhub", region_name=region)
        try:
            admins = sh.list_organization_admin_accounts().get("AdminAccounts", [])
            for a in admins:
                found.setdefault(a["AccountId"], []).append(region)
        except ClientError as e:
            logger.warning(f"[{region}] list_organization_admin_accounts failed: {e}")

    if not found:
        return None
    if len(found) > 1:
        logger.warning(f"Multiple SH admins across regions: {found}. Using {next(iter(found))}.")
    admin_id, admin_regions = next(iter(found.items()))
    logger.info(f"SH delegated admin: {admin_id} (registered in {len(admin_regions)} region(s): {admin_regions})")
    return admin_id


def teardown_admin_region(admin_session, region):
    """
    On the delegated admin, per region:
      - Disable auto-enable so churn doesn't add members back.
      - List every member, disassociate and delete.
      - Delete the finding aggregator homed in this region (if any).
    """
    sh = admin_session.client("securityhub", region_name=region)
    ok = True

    try:
        sh.update_organization_configuration(AutoEnable=False, AutoEnableStandards="NONE")
        logger.info(f"[{region}] admin: auto_enable=False, auto_enable_standards=NONE")
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code == "InvalidAccessException":
            # SH not enabled here; nothing to do
            logger.info(f"[{region}] admin: Security Hub not enabled — skipping region")
            return True
        elif code == "AccessDeniedException":
            logger.info(f"[{region}] admin: update_organization_configuration denied (not admin in this region)")
        else:
            logger.error(f"[{region}] admin: update_organization_configuration failed: {e}")
            ok = False

    # Members
    member_ids = []
    try:
        paginator = sh.get_paginator("list_members")
        for page in paginator.paginate(OnlyAssociated=False):
            for m in page.get("Members", []):
                member_ids.append(m["AccountId"])
    except ClientError as e:
        logger.warning(f"[{region}] admin: list_members failed: {e}")
    if member_ids:
        logger.info(f"[{region}] admin: {len(member_ids)} member(s) to remove")
        for i in range(0, len(member_ids), 50):
            batch = member_ids[i:i + 50]
            try:
                sh.disassociate_members(AccountIds=batch)
                sh.delete_members(AccountIds=batch)
                logger.info(f"[{region}] admin: removed batch of {len(batch)}")
            except ClientError as e:
                logger.error(f"[{region}] admin: batch removal failed: {e}")
                ok = False
    else:
        logger.info(f"[{region}] admin: no members")

    # Finding aggregator (v1). Only exists in its home region; other regions return empty.
    try:
        aggs = sh.list_finding_aggregators().get("FindingAggregators", [])
        for a in aggs:
            arn = a["FindingAggregatorArn"]
            try:
                sh.delete_finding_aggregator(FindingAggregatorArn=arn)
                logger.info(f"[{region}] admin: deleted finding aggregator {arn}")
            except ClientError as e:
                logger.error(f"[{region}] admin: delete_finding_aggregator({arn}) failed: {e}")
                ok = False
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code not in ("InvalidAccessException", "ResourceNotFoundException"):
            logger.warning(f"[{region}] admin: list_finding_aggregators: {e}")

    return ok


def disable_admin_registration(payer_session, admin_id, regions):
    """Per region: remove the delegated admin registration from the payer."""
    ok = True
    for region in regions:
        sh = payer_session.client("securityhub", region_name=region)
        try:
            sh.disable_organization_admin_account(AdminAccountId=admin_id)
            logger.info(f"[{region}] payer: disable_organization_admin_account({admin_id}) OK")
        except ClientError as e:
            code = e.response["Error"]["Code"]
            if code == "ResourceNotFoundException":
                logger.info(f"[{region}] payer: no admin to disable")
            else:
                logger.error(f"[{region}] payer: disable_organization_admin_account failed: {e}")
                ok = False
    return ok


def scrub_account_region(client_factory, name, aid, region):
    """
    Per region on an account (member or admin):
      - disassociate_from_administrator_account (idempotent; unlinks the member
        relationship that persists even after the org-level delegated admin is gone).
      - Delete any finding aggregator OWNED by this account (member accounts see
        the admin's aggregator in list_finding_aggregators but cannot delete it —
        filter by ARN's embedded account ID to only touch our own).
      - disable_security_hub.
    """
    sh = client_factory(region)
    ok = True

    # Step 1: unlink from any lingering admin relationship (member-side cleanup)
    try:
        sh.disassociate_from_administrator_account()
        logger.info(f"[{region}] {name}: disassociated from administrator")
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("InvalidAccessException", "ResourceNotFoundException", "InvalidInputException"):
            # Not a member, or SH not enabled — nothing to disassociate
            pass
        else:
            logger.warning(f"[{region}] {name}: disassociate_from_administrator_account: {e}")

    # Step 2: if this account is an (ex-)admin, purge its member records so
    #         disable_security_hub isn't blocked by lingering associations.
    try:
        member_ids = []
        for page in sh.get_paginator("list_members").paginate(OnlyAssociated=False):
            for m in page.get("Members", []):
                member_ids.append(m["AccountId"])
        if member_ids:
            logger.info(f"[{region}] {name}: found {len(member_ids)} member record(s), removing")
            for i in range(0, len(member_ids), 50):
                batch = member_ids[i:i + 50]
                try:
                    sh.disassociate_members(AccountIds=batch)
                    sh.delete_members(AccountIds=batch)
                    logger.info(f"[{region}] {name}: removed batch of {len(batch)} member(s)")
                except ClientError as e:
                    logger.error(f"[{region}] {name}: delete_members batch failed: {e}")
                    ok = False
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code not in ("InvalidAccessException", "AccessDeniedException", "ResourceNotFoundException"):
            logger.warning(f"[{region}] {name}: list_members: {e}")

    # Step 3: delete finding aggregator(s) owned by this account only
    try:
        aggs = sh.list_finding_aggregators().get("FindingAggregators", [])
        for a in aggs:
            arn = a["FindingAggregatorArn"]
            # ARN format: arn:aws:securityhub:REGION:ACCOUNT_ID:finding-aggregator/UUID
            arn_account = arn.split(":")[4]
            if arn_account != aid:
                # This is the admin's aggregator viewed from a member — skip
                continue
            try:
                sh.delete_finding_aggregator(FindingAggregatorArn=arn)
                logger.info(f"[{region}] {name}: deleted finding aggregator {arn}")
            except ClientError as e:
                logger.error(f"[{region}] {name}: delete_finding_aggregator({arn}) failed: {e}")
                ok = False
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code not in ("InvalidAccessException", "ResourceNotFoundException"):
            logger.warning(f"[{region}] {name}: list_finding_aggregators: {e}")

    # Step 3: disable Security Hub
    try:
        sh.disable_security_hub()
        logger.info(f"[{region}] {name}: disable_security_hub OK")
    except ClientError as e:
        code = e.response["Error"]["Code"]
        # Both codes mean "SH is not enabled here" — treat as idempotent success.
        # InvalidAccessException = "Account is not subscribed to AWS Security Hub"
        # ResourceNotFoundException = "Account is not subscribed to Security Hub"
        if code in ("InvalidAccessException", "ResourceNotFoundException"):
            logger.info(f"[{region}] {name}: Security Hub already disabled")
        else:
            logger.error(f"[{region}] {name}: disable_security_hub failed: {e}")
            ok = False

    return ok


def main():
    payer_session = boto3.Session()
    payer_id = payer_session.client("sts").get_caller_identity()["Account"]
    logger.info(f"Payer: {payer_id}")

    regions = get_enabled_regions(payer_session)
    logger.info(f"Enabled regions ({len(regions)}): {regions}")

    accounts = get_all_accounts(payer_session)
    logger.info(f"Active org accounts: {len(accounts)}")

    total_ok = True

    # --- Step 1: discover delegated admin (scans every region — admin registration is per-region) ---
    admin_id = find_current_admin(payer_session, regions)
    if admin_id:
        logger.info(f"Current SH delegated admin: {admin_id}")
        admin_creds = assume_role(admin_id)
        if admin_creds is None:
            logger.error(
                f"Could not assume {ROLE_NAME} in delegated admin account {admin_id}. "
                f"Check that the role exists and trusts the payer."
            )
            sys.exit(1)
        admin_session = boto3.Session(**admin_creds)

        # --- Step 2: admin teardown ---
        logger.info("=" * 70)
        logger.info("Step 2: teardown on delegated admin")
        logger.info("=" * 70)
        for region in regions:
            if not teardown_admin_region(admin_session, region):
                total_ok = False

        # --- Step 2b: remove admin registration from payer ---
        logger.info("=" * 70)
        logger.info("Step 2b: disable_organization_admin_account on payer")
        logger.info("=" * 70)
        if not disable_admin_registration(payer_session, admin_id, regions):
            total_ok = False
    else:
        logger.info("No SH delegated admin currently registered — skipping admin teardown steps")

    # --- Step 3: scrub every account, every region ---
    logger.info("=" * 70)
    logger.info("Step 3: scrub every account in every region")
    logger.info("=" * 70)

    for acct in accounts:
        aid = acct["Id"]
        name = acct["Name"]
        logger.info(f"\n--- {name} ({aid}) ---")

        if aid == payer_id:
            def factory(region, s=payer_session):
                return s.client("securityhub", region_name=region)
        else:
            creds = assume_role(aid)
            if creds is None:
                logger.error(f"Skipping {name} ({aid}) — unable to assume role")
                total_ok = False
                continue

            def factory(region, c=creds):
                return boto3.client("securityhub", region_name=region, **c)

        for region in regions:
            if not scrub_account_region(factory, name, aid, region):
                total_ok = False

    logger.info("=" * 70)
    if total_ok:
        logger.info("Done. Security Hub CSPM fully disabled across the org.")
        sys.exit(0)
    else:
        logger.error("Done with errors. Review the log above.")
        sys.exit(1)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        sys.exit(1)
