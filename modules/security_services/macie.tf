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


# Explicitly enable Macie in the parent and security account
resource "aws_macie2_account" "payer_account" {
  count                        = local.security_services["disable_macie"] ? 0 : 1
  provider                     = aws.payer_account
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}

resource "aws_macie2_account" "security_account" {
  count                        = local.security_services["disable_macie"] ? 0 : 1
  provider                     = aws.security_account
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}

# Assign delegated admin to the security account via GuardDuty APIs
resource "aws_macie2_organization_admin_account" "macie" {
  count    = local.security_services["disable_macie"] ? 0 : 1
  provider = aws.payer_account
  depends_on = [
    aws_macie2_account.payer_account,
    aws_macie2_account.security_account,
  ]
  admin_account_id = var.security_account_id
}

resource "aws_macie2_classification_export_configuration" "export_config" {
  count    = local.security_services["disable_macie"] || var.macie_bucket_name == null || var.macie_key_arn == null ? 0 : 1
  provider = aws.security_account
  depends_on = [
    aws_macie2_account.security_account
  ]
  s3_destination {
    bucket_name = var.macie_bucket_name
    key_prefix  = "macie/"
    kms_key_arn = var.macie_key_arn
  }
}

# This adds all the existing accounts to the delegated admin
resource "aws_macie2_member" "member" {
  provider   = aws.security_account
  depends_on = [aws_macie2_organization_admin_account.macie]
  account_id = each.key
  email      = each.value["email"]
  invite     = false

  for_each = {
    # Thank you Stack Overflow for this
    # https://stackoverflow.com/questions/58594506/how-to-for-each-through-a-listobjects-in-terraform-0-12
    # https://stackoverflow.com/questions/75524827/is-there-a-way-to-exclude-items-inside-of-a-for-each
    # Security Account cannot be a member if itself and must be excluded from the list.

    # We cannot use count here either, so we must add the disable_guardduty flag
    for index, account in data.aws_organizations_organizational_unit_descendant_accounts.accounts.accounts :
    account.id => account if account.id != var.security_account_id && !local.security_services["disable_macie"]
  }

  lifecycle {
    ignore_changes = [
      email, invite
    ]
  }

}
