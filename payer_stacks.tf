# Copyright 2026 Chris Farris <chris@primeharbor.com>
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

locals {
  # Expand stack x regions so each stack-region pair gets a stable address
  # like aws_cloudformation_stack.payer["billing_alerts-us-east-1"]. When
  # regions is omitted, default to the base org-kickstart region.
  payer_stacks_expanded = merge([
    for k, v in var.payer_cloudformation_stacks : {
      for region in coalesce(v.regions, [data.aws_region.current.region]) : "${k}-${region}" => {
        stack_name         = v.stack_name
        template_file      = v.template_file
        template_url       = v.template_url
        region             = region
        parameters         = v.parameters
        timeout_in_minutes = v.timeout_in_minutes
        on_failure         = v.on_failure
      }
    }
  ]...)
}

resource "aws_cloudformation_stack" "payer" {
  for_each = local.payer_stacks_expanded

  name          = each.value.stack_name
  region        = each.value.region
  template_body = each.value.template_file != null ? file("${path.root}/${each.value.template_file}") : null
  template_url  = each.value.template_url

  # Canonicalize any parameter value that happens to parse as JSON so
  # whitespace-only differences (heredocs, indentation) don't show up as
  # drift on subsequent plans. Non-JSON strings pass through unchanged.
  parameters = {
    for k, v in each.value.parameters : k => try(jsonencode(jsondecode(v)), v)
  }

  timeout_in_minutes = each.value.timeout_in_minutes
  # on_failure         = each.value.on_failure

  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_NAMED_IAM",
    "CAPABILITY_AUTO_EXPAND"
  ]
}
