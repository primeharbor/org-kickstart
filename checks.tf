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
# Validation checks for org-kickstart configuration
# These checks validate the configuration without blocking apply operations
#

check "security_account_separation" {
  assert {
    condition     = module.security_account.account_id != aws_organizations_account.payer.id
    error_message = "Security account cannot be the same as the payer account. This violates the security boundary between management and security functions."
  }
}

check "security_account_in_governance_ou" {
  assert {
    condition     = aws_organizations_organizational_unit.governance_ou.id != ""
    error_message = "Governance OU must exist to hold the security account"
  }
}

check "organizational_units_created" {
  assert {
    condition = (
      aws_organizations_organizational_unit.governance_ou.id != "" &&
      aws_organizations_organizational_unit.workloads_ou.id != "" &&
      aws_organizations_organizational_unit.sandbox_ou.id != "" &&
      aws_organizations_organizational_unit.suspended_ou.id != ""
    )
    error_message = "All four required OUs (Governance, Workloads, Sandbox, Suspended) must be successfully created"
  }
}

check "sso_configuration_valid" {
  assert {
    condition = (
      var.disable_sso_management ||
      (
        length(data.aws_ssoadmin_instances.identity_store.arns) > 0 &&
        length(data.aws_ssoadmin_instances.identity_store.identity_store_ids) > 0
      )
    )
    error_message = "SSO management is enabled but no Identity Center instance was found. Ensure AWS Identity Center is enabled in the console before running org-kickstart."
  }
}

check "cloudtrail_configuration_consistent" {
  assert {
    condition = (
      var.cloudtrail_bucket_name == null ||
      (var.cloudtrail_bucket_name != null && var.cloudtrail_bucket_name != "")
    )
    error_message = "CloudTrail bucket name must be either null (disabled) or a non-empty string"
  }
}
