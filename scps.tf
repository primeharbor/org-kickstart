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

module "scp" {
  for_each           = var.service_control_policies
  source             = "./modules/scp"
  policy_name        = each.value["policy_name"]
  policy_description = each.value["policy_description"]
  policy_json        = templatefile(fileexists(each.value["policy_json_file"]) ? each.value["policy_json_file"] : "${path.module}/${each.value["policy_json_file"]}", lookup(each.value, "policy_vars", {}))
  policy_targets     = lookup(each.value, "policy_targets", [aws_organizations_organization.org.roots[0].id])
}


