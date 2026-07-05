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

#
# Security Hub 2.0 Support
# Ref: https://docs.aws.amazon.com/securityhub/latest/userguide/setting-up-cross-account-access.html
#

data "aws_caller_identity" "current" {}

locals {
  securityhub2_enabled = var.security_hub_configuration != null
  enable_securityhub2  = local.securityhub2_enabled && try(var.security_hub_configuration.enable_security_hub_2, false)
  create_cost_role     = local.securityhub2_enabled && try(var.security_hub_configuration.create_cost_estimation_role, true)
  create_org_policy    = local.securityhub2_enabled && try(var.security_hub_configuration.create_org_delegation_policy, true)

  # Only create the org admin delegation here if Security Hub v1 hasn't already done it.
  # v1 creates aws_securityhub_organization_admin_account when disable_securityhub = false.
  securityhub_v1_managing_org_admin = !try(var.security_services.disable_securityhub, true)
  create_securityhub2_org_admin     = local.enable_securityhub2 && !local.securityhub_v1_managing_org_admin

  payer_account_id   = data.aws_caller_identity.current.account_id
  security_account_id = module.security_account.account_id
  org_resource_id    = aws_organizations_organization.org.id

  # Statements for the Organization resource policy granting the security (delegated admin)
  # account permission to manage Security Hub 2.0 org-wide. Add more statement objects here
  # as additional services require org-level delegation.
  org_delegation_statements = [
    {
      Sid    = "SecurityServicesDelegatingOrgReadActions"
      Effect = "Allow"
      Principal = {
        AWS = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:root"
      }
      Action   = "organizations:ListRoots"
      Resource = "*"
    },
    {
      Sid    = "SecurityServicesDelegatingNecessaryOrgManagementActions"
      Effect = "Allow"
      Principal = {
        AWS = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:root"
      }
      Action = [
        "organizations:DescribeOrganization",
        "organizations:DescribeOrganizationalUnit",
        "organizations:DescribeAccount",
        "organizations:ListRoots",
        "organizations:ListOrganizationalUnitsForParent",
        "organizations:ListParents",
        "organizations:ListChildren",
        "organizations:ListAccounts",
        "organizations:ListAccountsForParent",
        "organizations:ListTagsForResource",
        "organizations:ListDelegatedAdministrators",
        "organizations:ListHandshakesForAccount"
      ]
      Resource = [
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:root/${local.org_resource_id}/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:organization/${local.org_resource_id}",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:ou/${local.org_resource_id}/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:account/${local.org_resource_id}/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:policy/${local.org_resource_id}/securityhub_policy/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:policy/${local.org_resource_id}/inspector_policy/*"
      ]
    },
    {
      Sid    = "SecurityServicesDelegatingPolicyDescribeActions"
      Effect = "Allow"
      Principal = {
        AWS = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:root"
      }
      Action = [
        "organizations:DescribePolicy",
        "organizations:DescribeEffectivePolicy",
        "organizations:ListPolicies",
        "organizations:ListPoliciesForTarget",
        "organizations:ListTargetsForPolicy"
      ]
      Resource = [
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:root/${local.org_resource_id}/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:ou/${local.org_resource_id}/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:account/${local.org_resource_id}/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:policy/${local.org_resource_id}/securityhub_policy/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:policy/${local.org_resource_id}/inspector_policy/*"
      ]
    },
    {
      Sid    = "SecurityServicesDelegatingPolicyMutationActions"
      Effect = "Allow"
      Principal = {
        AWS = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:root"
      }
      Action = [
        "organizations:CreatePolicy",
        "organizations:UpdatePolicy",
        "organizations:DeletePolicy",
        "organizations:AttachPolicy",
        "organizations:DetachPolicy",
        "organizations:EnablePolicyType",
        "organizations:DisablePolicyType"
      ]
      Resource = [
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:root/${local.org_resource_id}/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:ou/${local.org_resource_id}/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:account/${local.org_resource_id}/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:policy/${local.org_resource_id}/securityhub_policy/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:policy/${local.org_resource_id}/inspector_policy/*"
      ]
    },
    {
      Sid    = "SecurityServicesDelegatingPolicyTagActions"
      Effect = "Allow"
      Principal = {
        AWS = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:root"
      }
      Action = [
        "organizations:TagResource",
        "organizations:UntagResource"
      ]
      Resource = [
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:policy/${local.org_resource_id}/securityhub_policy/*",
        "arn:${data.aws_partition.current.partition}:organizations::${local.payer_account_id}:policy/${local.org_resource_id}/inspector_policy/*"
      ]
    }
  ]
}

# Cross-account IAM role in the management account allowing Security Hub 2.0 in the
# delegated admin (security) account to read Cost Explorer data for cost estimation.
# The role name is required exactly as-is by AWS Security Hub.
resource "aws_iam_role" "securityhub_cost_estimator" {
  count = local.create_cost_role ? 1 : 0
  name  = "AwsSecurityHubCostEstimatorCrossAccountRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecurityHubServiceRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:role/aws-service-role/securityhub.amazonaws.com/AWSServiceRoleForSecurityHub"
        }
        Action = "sts:AssumeRole"
      },
      {
        Sid    = "AllowSecurityAccountPrincipals"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "securityhub_cost_estimator" {
  count  = local.create_cost_role ? 1 : 0
  name   = "SecurityHubCostEstimatorPolicy"
  role   = aws_iam_role.securityhub_cost_estimator[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ce:GetCostAndUsage"
      Resource = "*"
    }]
  })
}

# Delegate the security account as the Security Hub 2.0 org administrator.
# Skipped when Security Hub v1 is also enabled (v1's security_hub.tf owns the delegation).
resource "aws_securityhub_organization_admin_account" "securityhub_v2" {
  count            = local.create_securityhub2_org_admin ? 1 : 0
  admin_account_id = local.security_account_id
}

# Enable Security Hub 2.0 in the security (delegated admin) account.
resource "aws_securityhub_account_v2" "security_account" {
  count    = local.enable_securityhub2 ? 1 : 0
  provider = aws.security-account
  depends_on = [aws_securityhub_organization_admin_account.securityhub_v2]
}

# Enable Security Hub 2.0 in the payer account.
resource "aws_securityhub_account_v2" "payer_account" {
  count    = local.enable_securityhub2 ? 1 : 0
  depends_on = [aws_securityhub_organization_admin_account.securityhub_v2]
}

# Aggregate findings from all enabled regions into the security account.
# ALL_REGIONS mode is documented but currently rejected by the AWS API; use
# SPECIFIED_REGIONS with the full list of enabled regions minus the aggregation region.
resource "aws_securityhub_aggregator_v2" "security_account" {
  count               = local.enable_securityhub2 ? 1 : 0
  provider            = aws.security-account
  region_linking_mode = "SPECIFIED_REGIONS"
  linked_regions = [
    for r in data.aws_regions.available.names :
    r if r != data.aws_region.current.region
  ]
  depends_on = [aws_securityhub_account_v2.security_account]
}

