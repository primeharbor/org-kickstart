#!/usr/bin/env python3
"""
Fully disable AWS Security Hub V2 (the "unified" hub) across the org.

Sibling to wipe_sechub_cspm.py (which handles v1/CSPM). Runs from the Organization
Management (payer) account. Order of operations:

  1. Per region on the payer: discover the v2 delegated admin
     (list_organization_admin_accounts with Feature=SecurityHubV2). The admin
     registration is per-region, so we scan every enabled region.
  2. If a v2 admin exists, assume ROLE_NAME into that account and tear it down:
     per region on the admin, list_aggregators_v2 + delete_aggregator_v2.
  3. Per region on the payer: disable_organization_admin_account(Feature=SecurityHubV2)
     to remove the admin registration in every region.
  4. Per account × per region (payer directly, members via
     OrganizationAccountAccessRole): delete any v2 aggregator owned by this account,
     then disable_security_hub_v2.

Unlike v1/CSPM, Security Hub V2 has no per-account member/admin association API — that
is entirely handled by the SECURITYHUB_POLICY at Root. So there is no list_members /
disassociate_members equivalent to run against v2.

Complements wipe_sechub_cspm.py.

Run as the payer. Uses only the payer's credentials — the delegated admin account is
discovered via list_organization_admin_accounts and accessed by assuming ROLE_NAME
(default: OrganizationAccountAccessRole) into it, same as every other member account.

Constants (edit at the top of the file if your setup differs):
  ROLE_NAME   — cross-account role assumed from the payer into each account, including
                the delegated admin. OrganizationAccountAccessRole is the org-kickstart
                default and is trusted by both the security account and every workload.
  HOME_REGION — region used for the initial describe_regions / list_accounts calls
                only; the destructive work spans every enabled region.
"""

import logging
import sys

import boto3
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

ROLE_NAME = "OrganizationAccountAccessRole"
HOME_REGION = "us-east-1"
FEATURE = "SecurityHubV2"


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
        creds = sts.assume_role(RoleArn=role_arn, RoleSessionName="wipe-sechub-v2")["Credentials"]
        return {
            "aws_access_key_id": creds["AccessKeyId"],
            "aws_secret_access_key": creds["SecretAccessKey"],
            "aws_session_token": creds["SessionToken"],
        }
    except ClientError as e:
        logger.error(f"assume_role({target_account_id}) failed: {e}")
        return None


def find_current_v2_admin(payer_session, regions):
    """
    Scan every region for a v2 delegated admin registration and return the account ID
    (or None). Same rationale as the CSPM script: SH admin state is per-region and can
    linger in a partial teardown state.
    """
    found = {}
    for region in regions:
        sh = payer_session.client("securityhub", region_name=region)
        try:
            admins = sh.list_organization_admin_accounts(Feature=FEATURE).get("AdminAccounts", [])
            for a in admins:
                found.setdefault(a["AccountId"], []).append(region)
        except ClientError as e:
            logger.warning(f"[{region}] list_organization_admin_accounts(v2) failed: {e}")

    if not found:
        return None
    if len(found) > 1:
        logger.warning(f"Multiple v2 admins across regions: {found}. Using {next(iter(found))}.")
    admin_id, admin_regions = next(iter(found.items()))
    logger.info(f"SH v2 delegated admin: {admin_id} (registered in {len(admin_regions)} region(s): {admin_regions})")
    return admin_id


def _aggregator_arn(agg):
    """AggregatorV2 shape varies slightly across SDK versions; try common keys."""
    for key in ("AggregatorV2Arn", "AggregatorArn", "Arn"):
        if key in agg:
            return agg[key]
    return None


def teardown_v2_admin_region(admin_session, region):
    """Delete any v2 aggregators the admin owns in this region."""
    sh = admin_session.client("securityhub", region_name=region)
    ok = True
    try:
        aggs = sh.list_aggregators_v2().get("AggregatorsV2", [])
        for a in aggs:
            arn = _aggregator_arn(a)
            if not arn:
                logger.warning(f"[{region}] admin: v2 aggregator with no recognizable ARN key: {a}")
                continue
            try:
                sh.delete_aggregator_v2(AggregatorV2Arn=arn)
                logger.info(f"[{region}] admin: deleted v2 aggregator {arn}")
            except ClientError as e:
                logger.error(f"[{region}] admin: delete_aggregator_v2({arn}) failed: {e}")
                ok = False
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code not in ("InvalidAccessException", "ResourceNotFoundException", "AccessDeniedException"):
            logger.warning(f"[{region}] admin: list_aggregators_v2: {e}")
    return ok


def disable_v2_admin_registration(payer_session, admin_id, regions):
    ok = True
    for region in regions:
        sh = payer_session.client("securityhub", region_name=region)
        try:
            sh.disable_organization_admin_account(AdminAccountId=admin_id, Feature=FEATURE)
            logger.info(f"[{region}] payer: disable_organization_admin_account(v2, {admin_id}) OK")
        except ClientError as e:
            code = e.response["Error"]["Code"]
            if code == "ResourceNotFoundException":
                logger.info(f"[{region}] payer: no v2 admin to disable")
            else:
                logger.error(f"[{region}] payer: disable_organization_admin_account(v2) failed: {e}")
                ok = False
    return ok


def scrub_v2_account_region(client_factory, name, aid, region):
    """
    Per region on an account (member or admin):
      - Delete any v2 aggregator OWNED by this account (filter by ARN's account ID
        so members don't try to delete the admin's aggregator).
      - disable_security_hub_v2.
    """
    sh = client_factory(region)
    ok = True

    # Delete v2 aggregator(s) owned by this account
    try:
        aggs = sh.list_aggregators_v2().get("AggregatorsV2", [])
        for a in aggs:
            arn = _aggregator_arn(a) or ""
            # ARN format: arn:aws:securityhub:REGION:ACCOUNT:aggregator/UUID
            arn_account = arn.split(":")[4] if arn.count(":") >= 5 else ""
            if arn_account != aid:
                continue
            try:
                sh.delete_aggregator_v2(AggregatorV2Arn=arn)
                logger.info(f"[{region}] {name}: deleted v2 aggregator {arn}")
            except ClientError as e:
                logger.error(f"[{region}] {name}: delete_aggregator_v2({arn}) failed: {e}")
                ok = False
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code not in ("InvalidAccessException", "ResourceNotFoundException", "AccessDeniedException"):
            logger.warning(f"[{region}] {name}: list_aggregators_v2: {e}")

    # Disable SH v2
    try:
        sh.disable_security_hub_v2()
        logger.info(f"[{region}] {name}: disable_security_hub_v2 OK")
    except ClientError as e:
        code = e.response["Error"]["Code"]
        # Both mean "SH V2 isn't enabled here" — idempotent success.
        if code in ("InvalidAccessException", "ResourceNotFoundException"):
            logger.info(f"[{region}] {name}: Security Hub V2 already disabled")
        else:
            logger.error(f"[{region}] {name}: disable_security_hub_v2 failed: {e}")
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

    # --- Step 1: discover v2 delegated admin (per region) ---
    admin_id = find_current_v2_admin(payer_session, regions)
    if admin_id:
        admin_creds = assume_role(admin_id)
        if admin_creds is None:
            logger.error(
                f"Could not assume {ROLE_NAME} in v2 delegated admin account {admin_id}. "
                f"Check that the role exists and trusts the payer."
            )
            sys.exit(1)
        admin_session = boto3.Session(**admin_creds)

        # --- Step 2: admin teardown (delete v2 aggregators) ---
        logger.info("=" * 70)
        logger.info("Step 2: teardown v2 admin (delete aggregators)")
        logger.info("=" * 70)
        for region in regions:
            if not teardown_v2_admin_region(admin_session, region):
                total_ok = False

        # --- Step 2b: remove v2 admin registration from payer ---
        logger.info("=" * 70)
        logger.info("Step 2b: disable_organization_admin_account(v2) on payer")
        logger.info("=" * 70)
        if not disable_v2_admin_registration(payer_session, admin_id, regions):
            total_ok = False
    else:
        logger.info("No SH v2 delegated admin currently registered — skipping admin teardown steps")

    # --- Step 3: scrub every account × every region ---
    logger.info("=" * 70)
    logger.info("Step 3: disable_security_hub_v2 in every account × every region")
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
            if not scrub_v2_account_region(factory, name, aid, region):
                total_ok = False

    logger.info("=" * 70)
    if total_ok:
        logger.info("Done. Security Hub V2 fully disabled across the org.")
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
