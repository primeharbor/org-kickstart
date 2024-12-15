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
  count    = local.security_services["disable_guardduty"] ? 0 : 1
  provider = aws.payer_account
  enable   = true
}

resource "aws_guardduty_detector" "security_detector" {
  count    = local.security_services["disable_guardduty"] ? 0 : 1
  provider = aws.security_account
  enable   = true
}

# Assign delegated admin to the security account via GuardDuty APIs
resource "aws_guardduty_organization_admin_account" "guardduty" {
  count    = local.security_services["disable_guardduty"] ? 0 : 1
  provider = aws.payer_account
  depends_on = [
    aws_guardduty_detector.payer_detector,
    aws_guardduty_detector.security_detector,
  ]
  admin_account_id = var.security_account_id
}

# This sets up the default settings
resource "aws_guardduty_organization_configuration" "organization" {
  count                            = local.security_services["disable_guardduty"] ? 0 : 1
  depends_on                       = [aws_guardduty_organization_admin_account.guardduty]
  provider                         = aws.security_account
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.security_detector[0].id
}

