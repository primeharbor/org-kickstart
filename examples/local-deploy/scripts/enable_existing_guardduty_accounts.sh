#!/bin/bash

# Copyright 2026 Chris Farris <chris@primeharbor.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# enable_existing_guardduty_accounts.sh
#
# One-shot helper: enroll every existing organization account as a GuardDuty
# member of the current delegated admin, in every enabled region.
#
# Why this is needed: aws_guardduty_organization_configuration with
# auto_enable_organization_members = "ALL" only fires for NEW accounts as they
# join the organization. Existing accounts that were never members (or that
# were explicitly disassociated via DeleteMembers) are NOT retroactively
# enrolled — they show up in the console as "Not a member" even though the
# auto-enable is on. This script fills that gap by calling CreateMembers for
# every existing account in every region.
#
# Once accounts are members, subsequent GuardDuty configuration changes
# (feature enablement, etc.) propagate normally. This is a one-time thing per
# fresh org setup or per re-enrolment after a wipe.
#
# Flow:
#   1. From the payer, discover the GD delegated admin via
#      list-organization-admin-accounts.
#   2. Enumerate every ACTIVE org account except the admin itself.
#   3. Assume OrganizationAccountAccessRole into the delegated admin.
#   4. For each enabled region, get the admin's detector-id and call
#      CreateMembers with the full account list.
#
# Safe to re-run: already-enrolled accounts land in UnprocessedAccounts with
# an "already a member" error and are reported but not treated as a failure.
#
# Requires: aws CLI, jq. Run as the payer account with credentials in the
# environment (or the default profile).
#

set -euo pipefail

ROLE_NAME="OrganizationAccountAccessRole"
HOME_REGION="${HOME_REGION:-us-east-1}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

info()  { echo -e "$(date '+%H:%M:%S') ${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "$(date '+%H:%M:%S') ${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "$(date '+%H:%M:%S') ${RED}[ERROR]${NC} $*"; }

command -v aws >/dev/null || { error "aws CLI not found"; exit 1; }
command -v jq  >/dev/null || { error "jq not found"; exit 1; }

# --- Step 1: discover the delegated admin from the payer ---
PAYER_ID=$(aws sts get-caller-identity --query 'Account' --output text)
info "Running as payer: ${PAYER_ID}"

ADMIN_ID=$(aws guardduty list-organization-admin-accounts \
  --region "$HOME_REGION" \
  --query 'AdminAccounts[0].AdminAccountId' \
  --output text 2>/dev/null || echo "None")

if [[ "$ADMIN_ID" == "None" || -z "$ADMIN_ID" ]]; then
  error "No GuardDuty delegated admin registered in ${HOME_REGION}. Enable GD first."
  exit 1
fi
info "GD delegated admin: ${ADMIN_ID}"

# --- Step 2: enumerate enabled regions and accounts ---
REGIONS=$(aws ec2 describe-regions --region "$HOME_REGION" \
  --query "Regions[?OptInStatus=='opt-in-not-required' || OptInStatus=='opted-in'].RegionName" \
  --output text)
REGION_COUNT=$(echo "$REGIONS" | wc -w | tr -d ' ')
info "Enabled regions (${REGION_COUNT}): ${REGIONS}"

# Get every ACTIVE account except the delegated admin itself. The admin can't
# be its own GD member — CreateMembers rejects the admin's own account id.
ACCOUNT_DETAILS=$(aws organizations list-accounts \
  --query "Accounts[?Status=='ACTIVE' && Id!='${ADMIN_ID}'].{AccountId:Id,Email:Email}" \
  --output json)
ACCOUNT_COUNT=$(echo "$ACCOUNT_DETAILS" | jq 'length')
info "Accounts to enroll: ${ACCOUNT_COUNT}"

if [[ "$ACCOUNT_COUNT" -eq 0 ]]; then
  warn "No accounts to enroll (nothing but the admin?). Exiting."
  exit 0
fi

# CreateMembers accepts up to 50 accounts per call; batch if the org is bigger.
if [[ "$ACCOUNT_COUNT" -gt 50 ]]; then
  warn "Org has ${ACCOUNT_COUNT} non-admin accounts; CreateMembers caps at 50 per call."
  warn "This script will batch the list into groups of 50 per region."
fi

# --- Step 3: assume into the delegated admin ---
info "Assuming ${ROLE_NAME} in delegated admin ${ADMIN_ID}..."
CREDS_JSON=$(aws sts assume-role \
  --role-arn "arn:aws:iam::${ADMIN_ID}:role/${ROLE_NAME}" \
  --role-session-name "enable-existing-guardduty-accounts" \
  --output json)
export AWS_ACCESS_KEY_ID=$(echo "$CREDS_JSON"     | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS_JSON" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$CREDS_JSON"     | jq -r '.Credentials.SessionToken')

# --- Step 4: for each region, call CreateMembers ---
TOTAL_OK=0
TOTAL_UNPROCESSED=0
TOTAL_FAIL_REGIONS=0

for REGION in $REGIONS; do
  DETECTOR_ID=$(aws guardduty list-detectors --region "$REGION" \
    --query 'DetectorIds[0]' --output text 2>/dev/null || echo "None")

  if [[ "$DETECTOR_ID" == "None" || -z "$DETECTOR_ID" ]]; then
    warn "[${REGION}] delegated admin has no detector — skipping"
    TOTAL_FAIL_REGIONS=$((TOTAL_FAIL_REGIONS + 1))
    continue
  fi

  info "[${REGION}] admin detector: ${DETECTOR_ID}"

  # Chunk the account list into batches of 50 (the CreateMembers API limit).
  REGION_OK=0
  REGION_UNPROCESSED=0
  BATCH_COUNT=$(( (ACCOUNT_COUNT + 49) / 50 ))
  for ((i = 0; i < BATCH_COUNT; i++)); do
    BATCH=$(echo "$ACCOUNT_DETAILS" | jq -c ".[$((i*50)):$(((i+1)*50))]")
    UNPROCESSED=$(aws guardduty create-members \
      --region "$REGION" \
      --detector-id "$DETECTOR_ID" \
      --account-details "$BATCH" \
      --query 'UnprocessedAccounts' --output json 2>&1) || {
      error "[${REGION}] CreateMembers batch $((i+1))/${BATCH_COUNT} failed: ${UNPROCESSED}"
      TOTAL_FAIL_REGIONS=$((TOTAL_FAIL_REGIONS + 1))
      continue 2
    }

    BATCH_SIZE=$(echo "$BATCH" | jq 'length')
    UNPROC_COUNT=$(echo "$UNPROCESSED" | jq 'length')
    REGION_OK=$((REGION_OK + BATCH_SIZE - UNPROC_COUNT))
    REGION_UNPROCESSED=$((REGION_UNPROCESSED + UNPROC_COUNT))

    if [[ "$UNPROC_COUNT" -gt 0 ]]; then
      # Log which accounts were unprocessed and why. Most common reason: already a member.
      echo "$UNPROCESSED" | jq -r '.[] | "  " + .AccountId + " : " + .Result' | while read L; do
        warn "[${REGION}] $L"
      done
    fi
  done

  info "[${REGION}] enrolled: ${REGION_OK}, unprocessed: ${REGION_UNPROCESSED}"
  TOTAL_OK=$((TOTAL_OK + REGION_OK))
  TOTAL_UNPROCESSED=$((TOTAL_UNPROCESSED + REGION_UNPROCESSED))
done

echo ""
info "Done."
info "Enrolled     : ${TOTAL_OK}"
info "Unprocessed  : ${TOTAL_UNPROCESSED}  (mostly \"already a member\" — safe to ignore)"
info "Failed regions: ${TOTAL_FAIL_REGIONS}"

if [[ "$TOTAL_FAIL_REGIONS" -gt 0 ]]; then
  exit 1
fi
