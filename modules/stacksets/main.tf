# Copyright 2024 Chris Farris <chris@primeharbor.com>
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

resource "aws_cloudformation_stack_set" "stack_set" {
  provider         = aws.security-account
  name             = var.stack_set_name
  permission_model = "SERVICE_MANAGED"
  call_as          = "DELEGATED_ADMIN"
  description      = var.stack_set_description
  template_body    = local.stack_set_template_body
  template_url     = local.stack_set_template_url
  parameters       = var.parameters

  # Bug with provider https://github.com/hashicorp/terraform-provider-aws/issues/23464
  # TF attempts to remove the administration_role_arn, even though it's added as part of a tf refresh
  # Workaround is the lifecycle block
  # administration_role_arn = "arn:aws:iam::${local.payer_account_id}:role/aws-service-role/stacksets.cloudformation.amazonaws.com/AWSServiceRoleForCloudFormationStackSetsOrgAdmin"
  lifecycle {
    ignore_changes = [
      administration_role_arn
    ]
  }
  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = var.retain_stack
  }

  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_NAMED_IAM",
    "CAPABILITY_AUTO_EXPAND"
  ]

  operation_preferences {
    failure_tolerance_percentage = 0
    max_concurrent_percentage    = 100
  }
}

resource "aws_cloudformation_stack_set_instance" "stack_set" {
  provider       = aws.security-account
  region         = var.region
  call_as        = "DELEGATED_ADMIN"
  retain_stack   = var.retain_stack
  stack_set_name = aws_cloudformation_stack_set.stack_set.name
  deployment_targets {
    organizational_unit_ids = [aws_organizations_organization.org.roots[0].id]
  }
  operation_preferences {
    failure_tolerance_percentage = 0
    max_concurrent_percentage    = 100
  }
}


#
# Delegated Admin Stacksets doesn't deploy to the payer
#
resource "aws_cloudformation_stack" "payer_stack" {
  name          = var.stack_set_name
  template_body = local.stack_set_template_body
  template_url  = local.stack_set_template_url
  parameters    = var.parameters
  capabilities = [
    "CAPABILITY_NAMED_IAM"
  ]
}
