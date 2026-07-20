#!/usr/bin/env python3
"""
Fully disable Amazon GuardDuty across the entire organization.

Sibling to wipe_sechub_cspm.py and wipe_sechub_v2.py. Runs from the Organization
Management (payer) account. Uses only the payer's credentials — the delegated admin
account is discovered via list_organization_admin_accounts and accessed by assuming
ROLE_NAME (default: OrganizationAccountAccessRole) into it, same as every other
member account.

Handles both scenarios:

  * A current GuardDuty delegated admin is registered — full teardown flow (turn off
    auto-enable so nothing sneaks back in, disassociate + delete members, remove the
    delegated admin registration).
  * No current delegated admin — skip the admin steps and just scrub each account.

After the (optional) admin teardown, the script iterates every ACTIVE account in
the org, assumes ROLE_NAME where necessary, and in every enabled region disables +
deletes the detector.

Constants (edit at the top of the file if your setup differs):
  ROLE_NAME   — cross-account role assumed from the payer into each account,
                including the delegated admin. OrganizationAccountAccessRole is the
                org-kickstart default and is trusted by both the security account
                and every workload.
  HOME_REGION — region used for the initial describe_regions / list_accounts calls
                only; the destructive work spans every enabled region.

Exits 0 if every operation succeeded; 1 if any errors were logged.

Replaces the earlier predisable_guardduty_delegation.py + disable_guardduty.py pair
from pht-org-terraform.
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
    """
    Assume ROLE_NAME into target_account_id using an already-created STS client
    (typically the payer's). Reusing one client avoids re-resolving SSO credentials
    on every call, which — with SSO profiles — hits the token cache once instead of
    once per member account.
    """
    role_arn = f"arn:aws:iam::{target_account_id}:role/{ROLE_NAME}"
    try:
        creds = sts.assume_role(RoleArn=role_arn, RoleSessionName="wipe-guardduty")["Credentials"]
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
    Return the account ID of the GuardDuty delegated admin, or None. Scans every
    region because the registration is per-region and can linger in a partial
    teardown state.
    """
    found = {}
    for region in regions:
        gd = payer_session.client("guardduty", region_name=region)
        try:
            admins = gd.list_organization_admin_accounts().get("AdminAccounts", [])
            for a in admins:
                found.setdefault(a["AdminAccountId"], []).append(region)
        except ClientError as e:
            logger.warning(f"[{region}] list_organization_admin_accounts failed: {e}")

    if not found:
        return None
    if len(found) > 1:
        logger.warning(f"Multiple GD admins across regions: {found}. Using {next(iter(found))}.")
    admin_id, admin_regions = next(iter(found.items()))
    logger.info(f"GD delegated admin: {admin_id} (registered in {len(admin_regions)} region(s): {admin_regions})")
    return admin_id


def teardown_admin_region(admin_session, region):
    """
    On the delegated admin, per region:
      - Turn off AutoEnableOrganizationMembers so nothing sneaks back in
        mid-teardown.
      - list_members, disassociate + delete every member in batches of 50.
    Do NOT delete the admin's own detector here — that has to wait until after
    the admin registration is removed from the payer (Step 2b). The admin's
    detector is picked up by the scrub step at the very end.
    """
    gd = admin_session.client("guardduty", region_name=region)
    ok = True

    try:
        detectors = gd.list_detectors().get("DetectorIds", [])
    except ClientError as e:
        logger.error(f"[{region}] admin: list_detectors failed: {e}")
        return False

    if not detectors:
        logger.info(f"[{region}] admin: no detector — skipping region")
        return True

    detector_id = detectors[0]
    logger.info(f"[{region}] admin: detector {detector_id}")

    # Turn off auto-enable so new members don't get added during teardown.
    try:
        gd.update_organization_configuration(
            DetectorId=detector_id,
            AutoEnableOrganizationMembers="NONE",
        )
        logger.info(f"[{region}] admin: AutoEnableOrganizationMembers=NONE")
    except ClientError as e:
        logger.warning(f"[{region}] admin: update_organization_configuration failed (continuing): {e}")

    # Members
    member_ids = []
    try:
        paginator = gd.get_paginator("list_members")
        for page in paginator.paginate(DetectorId=detector_id, OnlyAssociated="false"):
            for m in page.get("Members", []):
                member_ids.append(m["AccountId"])
    except ClientError as e:
        logger.warning(f"[{region}] admin: list_members failed: {e}")

    if member_ids:
        logger.info(f"[{region}] admin: {len(member_ids)} member(s) to remove")
        for i in range(0, len(member_ids), 50):
            batch = member_ids[i:i + 50]
            try:
                gd.disassociate_members(DetectorId=detector_id, AccountIds=batch)
                gd.delete_members(DetectorId=detector_id, AccountIds=batch)
                logger.info(f"[{region}] admin: removed batch of {len(batch)} member(s)")
            except ClientError as e:
                logger.error(f"[{region}] admin: batch removal failed: {e}")
                ok = False
    else:
        logger.info(f"[{region}] admin: no members")

    return ok


def disable_admin_registration(payer_session, admin_id, regions):
    """Per region: remove the delegated admin registration from the payer."""
    ok = True
    for region in regions:
        gd = payer_session.client("guardduty", region_name=region)
        try:
            gd.disable_organization_admin_account(AdminAccountId=admin_id)
            logger.info(f"[{region}] payer: disable_organization_admin_account({admin_id}) OK")
        except ClientError as e:
            code = e.response["Error"]["Code"]
            if code in ("BadRequestException", "ResourceNotFoundException"):
                # Already-not-an-admin cases both surface as BadRequestException.
                logger.info(f"[{region}] payer: no admin to disable (already clean)")
            else:
                logger.error(f"[{region}] payer: disable_organization_admin_account failed: {e}")
                ok = False
    return ok


def scrub_account_region(client_factory, name, aid, region):
    """
    Per region on an account (member, current admin, or former admin whose registration
    was already destroyed out-of-band, e.g. by `terraform destroy` running the resources
    out of order relative to AWS-side member associations):

      1. list_detectors — no detector means nothing to do (and no valid DetectorId to
         pass to the member-side APIs, which AWS requires).
      2. For each detector:
         a. list_members. If any exist, this account is or was an admin — disassociate
            and delete them in batches of 50 before we try to delete the detector,
            otherwise DeleteDetector fails with "You must first disassociate your member
            accounts and delete invited member accounts." This step is a no-op on member
            accounts and idempotent when Step 2 (admin teardown) already ran.
         b. Best-effort disassociate from any lingering admin relationship (member-side
            cleanup).
         c. update_detector(Enable=False) then delete_detector.
    """
    gd = client_factory(region)
    ok = True

    try:
        detectors = gd.list_detectors().get("DetectorIds", [])
    except ClientError as e:
        logger.error(f"[{region}] {name}: list_detectors failed: {e}")
        return False

    if not detectors:
        logger.info(f"[{region}] {name}: no detector")
        return True

    for detector_id in detectors:
        # If this detector has members, this account is (or was) an admin. Disassociate
        # and delete them before trying to delete the detector, in batches of 50 to fit
        # the DisassociateMembers / DeleteMembers API limits.
        member_ids = []
        try:
            paginator = gd.get_paginator("list_members")
            for page in paginator.paginate(DetectorId=detector_id, OnlyAssociated="false"):
                for m in page.get("Members", []):
                    member_ids.append(m["AccountId"])
        except ClientError as e:
            # BadRequestException here typically means "this account is not an admin"
            # and list_members isn't callable — no members to clean up.
            code = e.response["Error"]["Code"]
            if code not in ("BadRequestException", "ResourceNotFoundException", "InvalidAccessException"):
                logger.warning(f"[{region}] {name}: list_members failed: {e}")

        if member_ids:
            logger.info(f"[{region}] {name}: detector {detector_id} has {len(member_ids)} member(s) — cleaning up")
            for i in range(0, len(member_ids), 50):
                batch = member_ids[i:i + 50]
                try:
                    gd.disassociate_members(DetectorId=detector_id, AccountIds=batch)
                    gd.delete_members(DetectorId=detector_id, AccountIds=batch)
                    logger.info(f"[{region}] {name}: removed batch of {len(batch)} member(s)")
                except ClientError as e:
                    logger.error(f"[{region}] {name}: batch removal failed: {e}")
                    ok = False

        # Unlink from any lingering admin association (member-side cleanup).
        # DisassociateFromAdministratorAccount requires the member's own DetectorId.
        try:
            gd.disassociate_from_administrator_account(DetectorId=detector_id)
            logger.info(f"[{region}] {name}: disassociated from administrator")
        except ClientError as e:
            code = e.response["Error"]["Code"]
            # BadRequestException typically = "not a member" — silent skip.
            if code not in ("BadRequestException", "ResourceNotFoundException", "InvalidAccessException"):
                logger.warning(f"[{region}] {name}: disassociate_from_administrator_account: {e}")

        try:
            gd.update_detector(DetectorId=detector_id, Enable=False)
            gd.delete_detector(DetectorId=detector_id)
            logger.info(f"[{region}] {name}: deleted detector {detector_id}")
        except ClientError as e:
            logger.error(f"[{region}] {name}: delete_detector({detector_id}) failed: {e}")
            ok = False

    return ok


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Fully disable Amazon GuardDuty across an AWS Organization, or scrub a "
            "single account when --account-id is supplied."
        ),
    )
    parser.add_argument(
        "--account-id",
        metavar="ACCOUNT_ID",
        help=(
            "Limit the wipe to a single account ID. Skips the org-wide admin teardown "
            "(steps 1, 2, 2b) and only scrubs the specified account in every enabled "
            "region. Useful for reclaiming a single stuck account without touching the "
            "rest of the org."
        ),
    )
    return parser.parse_args()


def main():
    args = parse_args()

    payer_session = boto3.Session()
    # Create the STS client once and reuse it across every assume_role call so SSO
    # profile credentials only get resolved once per run instead of once per member
    # account (~N × faster when running with SSO).
    sts = payer_session.client("sts")
    payer_id = sts.get_caller_identity()["Account"]
    logger.info(f"Payer: {payer_id}")

    regions = get_enabled_regions(payer_session)
    logger.info(f"Enabled regions ({len(regions)}): {regions}")

    accounts = get_all_accounts(payer_session)
    logger.info(f"Active org accounts: {len(accounts)}")

    # --- Single-account mode: skip the org-wide admin teardown and scrub only the
    # target account. The admin registration and other members are left alone. ---
    if args.account_id:
        target = next((a for a in accounts if a["Id"] == args.account_id), None)
        if target is None:
            logger.error(
                f"Account {args.account_id} not found among {len(accounts)} ACTIVE org accounts. "
                f"Verify the account ID and that it is a current member of the organization."
            )
            sys.exit(1)
        logger.info(
            f"--account-id set: skipping steps 1/2/2b; scrubbing only "
            f"{target['Name']} ({target['Id']})"
        )
        accounts = [target]

    total_ok = True

    if not args.account_id:
        # --- Step 1: discover the delegated admin (per-region scan) ---
        admin_id = find_current_admin(payer_session, regions)
        if admin_id:
            logger.info(f"Current GD delegated admin: {admin_id}")
            admin_creds = assume_role(sts, admin_id)
            if admin_creds is None:
                logger.error(
                    f"Could not assume {ROLE_NAME} in delegated admin account {admin_id}. "
                    f"Check that the role exists and trusts the payer."
                )
                sys.exit(1)
            admin_session = boto3.Session(**admin_creds)

            # --- Step 2: admin teardown ---
            logger.info("=" * 70)
            logger.info("Step 2: teardown on delegated admin (auto-enable off, remove members)")
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
            logger.info("No GD delegated admin currently registered — skipping admin teardown steps")

    # --- Step 3: scrub every account × every region ---
    logger.info("=" * 70)
    logger.info("Step 3: scrub every account in every region")
    logger.info("=" * 70)

    for acct in accounts:
        aid = acct["Id"]
        name = acct["Name"]
        logger.info(f"\n--- {name} ({aid}) ---")

        if aid == payer_id:
            def factory(region, s=payer_session):
                return s.client("guardduty", region_name=region)
        else:
            creds = assume_role(sts, aid)
            if creds is None:
                logger.error(f"Skipping {name} ({aid}) — unable to assume role")
                total_ok = False
                continue

            def factory(region, c=creds):
                return boto3.client("guardduty", region_name=region, **c)

        for region in regions:
            if not scrub_account_region(factory, name, aid, region):
                total_ok = False

    logger.info("=" * 70)
    if total_ok:
        logger.info("Done. GuardDuty fully disabled across the org.")
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
