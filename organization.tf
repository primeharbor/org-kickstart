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

#
# Define the Organization & enable as many services as makes sense
#
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "account.amazonaws.com",
    "backup.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "config.amazonaws.com",
    "fms.amazonaws.com",
    "guardduty.amazonaws.com",
    "inspector2.amazonaws.com",
    "license-management.marketplace.amazonaws.com",
    "license-manager.amazonaws.com",
    "license-manager.member-account.amazonaws.com",
    "macie.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]

  enabled_policy_types = [
    "AISERVICES_OPT_OUT_POLICY",
    "BACKUP_POLICY",
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]

  feature_set = "ALL"
}

