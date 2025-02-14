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


resource "aws_organizations_policy_attachment" "scp_attachment" {
  for_each  = toset(var.service_control_policies)
  policy_id = var.scp_name_to_id_map[each.value]
  target_id = aws_organizations_account.account.id
}

resource "aws_organizations_policy_attachment" "rcp_attachment" {
  for_each  = toset(var.resource_control_policies)
  policy_id = var.rcp_name_to_id_map[each.value]
  target_id = aws_organizations_account.account.id
}

resource "aws_organizations_policy_attachment" "dp_ec2_attachment" {
  for_each  = toset(var.declarative_policies_ec2)
  policy_id = var.dp_ec2_name_to_id_map[each.value]
  target_id = aws_organizations_account.account.id
}