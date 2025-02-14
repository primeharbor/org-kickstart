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
# Import with the following command:
#
#  terraform import 'module.organization.module.["Account Key in tfvars"].aws_organizations_account.account' AWSACCOUNTID
#

module "accounts" {
  for_each = var.accounts
  source   = "./modules/account"

  account_email             = each.value["account_email"]
  account_name              = each.value["account_name"]
  admin_group_id            = var.disable_sso_management ? null : aws_identitystore_group.admin_group[0].group_id
  admin_permission_set_arn  = var.disable_sso_management ? null : aws_ssoadmin_permission_set.admin_permission_set[0].arn
  billing_contact           = var.global_billing_contact
  budget_alert_recipients   = concat(lookup(each.value, "budget_alert_recipients", []), lookup(var.budget_defaults, "alert_recipients", []))
  default_close_on_deletion = var.default_close_on_deletion
  delegated_admin           = each.value.delegated_admin
  disable_sso_management    = var.disable_sso_management
  monthly_budget_amount     = lookup(each.value, "monthly_budget_amount", 0)
  operations_contact        = lookup(each.value, "operations_contact", null) == null ? var.global_operations_contact : each.value.operations_contact
  parent_ou_id              = local.ou_name_to_id[each.value.parent_ou_name]
  primary_contact           = lookup(each.value, "primary_contact", null) == null ? var.global_primary_contact : each.value.primary_contact
  security_contact          = var.global_security_contact
  service_control_policies  = lookup(each.value, "service_control_policies", [])
  resource_control_policies = lookup(each.value, "resource_control_policies", [])
  declarative_policies_ec2  = lookup(each.value, "declarative_policies_ec2", [])
  scp_name_to_id_map        = local.scp_name_to_id
  rcp_name_to_id_map        = local.rcp_name_to_id
  dp_ec2_name_to_id_map     = local.dp_ec2_name_to_id
}


# these are lookup tables needed by the account module
data "aws_organizations_policies" "scps" {
  filter = "SERVICE_CONTROL_POLICY"
}
data "aws_organizations_policies" "rcps" {
  filter = "RESOURCE_CONTROL_POLICY"
}
data "aws_organizations_policies" "dp_ec2" {
  filter = "DECLARATIVE_POLICY_EC2"
}

data "aws_organizations_policy" "scps" {
  for_each  = toset(data.aws_organizations_policies.scps.ids)
  policy_id = each.value
}
data "aws_organizations_policy" "rcps" {
  for_each  = toset(data.aws_organizations_policies.rcps.ids)
  policy_id = each.value
}
data "aws_organizations_policy" "dp_ec2" {
  for_each  = toset(data.aws_organizations_policies.dp_ec2.ids)
  policy_id = each.value
}

# Create a map to look up OU IDs by name. Thanks ChatGPT for almost getting there with what I needed.
locals {
  scp_name_to_id = {
    for scp in data.aws_organizations_policy.scps :
    scp.name => scp.policy_id
  }
  rcp_name_to_id = {
    for rcp in data.aws_organizations_policy.rcps :
    rcp.name => rcp.policy_id
  }
  dp_ec2_name_to_id = {
    for dp in data.aws_organizations_policy.dp_ec2 :
    dp.name => dp.policy_id
  }
}