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


resource "aws_organizations_policy" "ai_policy" {
  name    = "ai_policy"
  type    = "AISERVICES_OPT_OUT_POLICY"
  content = <<EOF
{
  "services": {
    "default": {
      "@@operators_allowed_for_child_policies": ["@@none"],
      "opt_out_policy": {
        "@@operators_allowed_for_child_policies": ["@@none"],
        "@@assign": "optOut"
      }
    }
  }
}
EOF
}

resource "aws_organizations_policy_attachment" "ai_policy_root" {
  policy_id = aws_organizations_policy.ai_policy.id
  target_id = aws_organizations_organization.org.roots[0].id
}