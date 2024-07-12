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

resource "aws_cloudformation_stack_set" "audit_role" {
  count            = var.deploy_audit_role == true ? 1 : 0
  provider         = aws.security-account
  name             = "audit-role-stackset"
  permission_model = "SERVICE_MANAGED"
  call_as          = "DELEGATED_ADMIN"
  description      = "Deploy the Audit Role to all AWS Accounts"
  template_url     = "https://s3.amazonaws.com/pht-cloudformation/aws-account-automation/AuditRole-Template.yaml"

  # Bug with provider https://github.com/hashicorp/terraform-provider-aws/issues/23464
  # TF attempts to remove the administration_role_arn, even though it's added as part of a tf refresh
  # Workaround is the lifecycle block
  # administration_role_arn = "arn:aws:iam::${local.payer_account_id}:role/aws-service-role/stacksets.cloudformation.amazonaws.com/AWSServiceRoleForCloudFormationStackSetsOrgAdmin"
  lifecycle {
    ignore_changes = [
      administration_role_arn
    ]
  }

  parameters = {
    TrustedAccountNumber = module.security_account.account_id
    RoleName             = var.audit_role_name
    DenyDataAccess       = false
  }

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = true
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

resource "aws_cloudformation_stack_set_instance" "audit_role" {
  count          = var.deploy_audit_role == true ? 1 : 0
  provider       = aws.security-account
  region         = "us-east-1"
  call_as        = "DELEGATED_ADMIN"
  retain_stack   = true
  stack_set_name = aws_cloudformation_stack_set.audit_role[0].name
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
resource "aws_cloudformation_stack" "audit_role_payer" {
  count        = var.deploy_audit_role == true ? 1 : 0
  name         = "audit-role"
  template_url = "https://s3.amazonaws.com/pht-cloudformation/aws-account-automation/AuditRole-Template.yaml"

  parameters = {
    TrustedAccountNumber = module.security_account.account_id
    RoleName             = var.audit_role_name
  }
  capabilities = [
    "CAPABILITY_NAMED_IAM"
  ]
}