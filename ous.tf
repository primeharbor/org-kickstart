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
# My go-to list of OUs for a basic org.
#

# Governance holds the security & payer accounts
resource "aws_organizations_organizational_unit" "governance_ou" {
  name      = "Governance"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Most accounts go here
resource "aws_organizations_organizational_unit" "workloads_ou" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create Sandbox accounts, if you want devs to have more service freedom
resource "aws_organizations_organizational_unit" "sandbox_ou" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Accounts you're going to close or have closed go here.
resource "aws_organizations_organizational_unit" "suspended_ou" {
  name      = "Suspended"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Fetch the list of AWS Organizational Units
data "aws_organizations_organizational_units" "all_ous" {
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create a map to look up OU IDs by name. Thanks ChatGPT for almost getting there with what I needed.
locals {
  ou_name_to_id = {
    for ou in data.aws_organizations_organizational_units.all_ous.children :
    ou.name => ou.id
  }
}

# Accounts you're going to close or have closed go here.
resource "aws_organizations_organizational_unit" "custom_ous" {
  for_each  = var.organizational_units
  name      = each.value["name"]
  parent_id = each.value["is_child_of_root"] ? aws_organizations_organization.org.roots[0].id : local.ou_name_to_id[each.value["parent_id"]]
}
