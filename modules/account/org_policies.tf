# Copyright 2025 Chris Farris <chris@primeharbor.com>
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

resource "aws_organizations_policy_attachment" "scp_attachment" {
  for_each  = toset(var.service_control_policies)
  policy_id = local.scp_name_to_id[each.value]
  target_id = aws_organizations_account.account.id
}

resource "aws_organizations_policy_attachment" "rcp_attachment" {
  for_each  = toset(var.resource_control_policies)
  policy_id = local.rcp_name_to_id[each.value]
  target_id = aws_organizations_account.account.id
}

resource "aws_organizations_policy_attachment" "dp_ec2_attachment" {
  for_each  = toset(var.declarative_policies_ec2)
  policy_id = local.dp_ec2_name_to_id[each.value]
  target_id = aws_organizations_account.account.id
}