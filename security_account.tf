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

# The security account is special. It:
# * Holds the CloudTrail Bucket
# * Is trusted by all the other accounts for the security-audit role
# * Is delegated administrator for a number of security services

# For more about the security account, see:
# https://www.chrisfarris.com/post/securityaccount/
# https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/security-ou-and-accounts.html#security-tooling-accounts


# We explictly create a security account.
module "security_account" {
  source = "./modules/account"

  account_email             = var.security_account_root_email
  account_name              = var.security_account_name
  admin_group_id            = var.disable_sso_management ? null : aws_identitystore_group.admin_group[0].group_id
  admin_permission_set_arn  = var.disable_sso_management ? null : aws_ssoadmin_permission_set.admin_permission_set[0].arn
  billing_contact           = var.global_billing_contact
  budget_alert_recipients   = concat(lookup(var.security_account, "budget_alert_recipients", []), lookup(var.budget_defaults, "alert_recipients", []))
  default_close_on_deletion = false
  delegated_admin           = lookup(var.security_account, "delegated_admin", [])
  disable_sso_management    = var.disable_sso_management
  monthly_budget_amount     = lookup(var.security_account, "monthly_budget_amount", 0)
  operations_contact        = var.global_operations_contact
  parent_ou_id              = aws_organizations_organizational_unit.governance_ou.id
  primary_contact           = var.global_primary_contact
  security_contact          = var.global_security_contact
  scp_name_to_id_map        = local.scp_name_to_id
  rcp_name_to_id_map        = local.rcp_name_to_id
  dp_ec2_name_to_id_map     = local.dp_ec2_name_to_id
}


# And delegate power to it
resource "aws_organizations_delegated_administrator" "cloudformation" {
  count             = local.security_services["disable_stacksets"] ? 0 : 1
  account_id        = module.security_account.account_id
  service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "health" {
  account_id        = module.security_account.account_id
  service_principal = "health.amazonaws.com"
}
