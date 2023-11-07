# Copyright 2023 Chris Farris <chris@primeharbor.com>
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


# Explictly create the detectors in the parent and security account
resource "aws_guardduty_detector" "payer_detector" {
  count    = var.disable_guardduty ? 0 : 1
  provider = aws.payer_account
  enable   = true
}

resource "aws_guardduty_detector" "security_detector" {
  count    = var.disable_guardduty ? 0 : 1
  provider = aws.security_account
  enable   = true
}

# Note: this is not needed because the aws_guardduty_organization_admin_account resource superceeds it.
# resource "aws_organizations_delegated_administrator" "guardduty" {
#   provider = aws.payer_account
#   depends_on = [aws_guardduty_detector.payer_detector]
#   account_id        = var.security_account_id
#   service_principal = "guardduty.amazonaws.com"
# }

# Assign delegated admin to the security account via GuardDuty APIs
resource "aws_guardduty_organization_admin_account" "guardduty" {
  count    = var.disable_guardduty ? 0 : 1
  provider = aws.payer_account
  depends_on = [
    aws_guardduty_detector.payer_detector,
    aws_guardduty_detector.security_detector,
  ]
  admin_account_id = var.security_account_id
}

# This sets up the default settings
resource "aws_guardduty_organization_configuration" "organization" {
  count                            = var.disable_guardduty ? 0 : 1
  depends_on                       = [aws_guardduty_organization_admin_account.guardduty]
  provider                         = aws.security_account
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.security_detector[0].id
}

# This adds all the existing accounts to the delegated admin
resource "aws_guardduty_member" "member" {
  provider    = aws.security_account
  depends_on  = [aws_guardduty_organization_configuration.organization]
  account_id  = each.key
  detector_id = aws_guardduty_detector.security_detector[0].id
  email       = each.value["email"]
  invite      = false

  for_each = {
    # Thank you Stack Overflow for this
    # https://stackoverflow.com/questions/58594506/how-to-for-each-through-a-listobjects-in-terraform-0-12
    # https://stackoverflow.com/questions/75524827/is-there-a-way-to-exclude-items-inside-of-a-for-each
    # Security Account cannot be a member if itself and must be excluded from the list.

    # We cannot use count here either, so we must add the disable_guardduty flag
    for index, account in data.aws_organizations_organizational_unit_descendant_accounts.accounts.accounts :
    account.id => account if account.id != var.security_account_id && !var.disable_guardduty
  }

  lifecycle {
    ignore_changes = [
      email, invite
    ]
  }

}