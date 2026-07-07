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

# Enabled (non-opt-in and opted-in) regions in the current partition. Used by
# every per-region resource in this file (v2 hubs, GuardDuty detectors, etc.).
data "aws_regions" "available" {
  all_regions = false
}

locals {
  securityhub2_enabled = var.security_hub_configuration != null
  enable_securityhub2  = local.securityhub2_enabled && try(var.security_hub_configuration.enable_security_hub_2, false)
  create_cost_role     = local.securityhub2_enabled && try(var.security_hub_configuration.create_cost_estimation_role, true)
  create_org_policy    = local.securityhub2_enabled && try(var.security_hub_configuration.create_org_delegation_policy, true)

  # Tri-state root action for each service:
  #   true  → attach the enable policy to Root
  #   false → attach the disable policy to Root (SH/Inspector are one-shot; detaching
  #           the enable policy does NOT disable the service — you must explicitly
  #           attach a disable policy to reverse it)
  #   null  → attach neither (org kickstart is not managing root-level enablement)
  # The policies themselves are always created when security_hub_configuration is
  # present so they are available to attach/detach at any time.
  sechub_root_action    = local.securityhub2_enabled ? try(var.security_hub_configuration.enable_security_hub_for_all_accounts, null) : null
  inspector_root_action = local.securityhub2_enabled ? try(var.security_hub_configuration.enable_inspector_for_all_accounts, null) : null

  # GuardDuty ("foundational threat detection") is enabled when
  # security_hub_configuration.enable_threat_detection is explicitly true. Absent OR
  # false → GuardDuty is not managed by this module. The SH v2 console UX calls the
  # equivalent action a "deployment" and warns that new accounts won't be auto-enrolled —
  # we sidestep that by creating aws_guardduty_organization_configuration with
  # auto_enable_organization_members = "ALL", so every new org account gets a detector
  # automatically going forward.
  enable_guardduty = local.securityhub2_enabled && try(var.security_hub_configuration.enable_threat_detection, false)

  # Security Hub CSPM (central-config-driven standards enablement). When true,
  # v2's delegated admin creates the CENTRAL organization configuration, a
  # configuration policy carrying the operator's chosen standards, and attaches
  # that policy to the Root OU. Requires enable_security_hub_2 = true (v2 hubs +
  # delegated admin). Empty security_hub_cspm_enabled_standard_arns means "no
  # standards enabled" (central config still switched on with SH enabled but no
  # standards) — set it to at least the AWS Foundational Security Best Practices
  # ARN for the recommended baseline.
  enable_security_hub_cspm                = local.enable_securityhub2 && try(var.security_hub_configuration.enable_security_hub_cspm, false)
  security_hub_cspm_enabled_standard_arns = try(var.security_hub_configuration.security_hub_cspm_enabled_standard_arns, [])

  # Extended GuardDuty features. threat_detection_features uses friendly snake_case
  # names on the tfvars side; we translate to the AWS API's UPPER_SNAKE_CASE feature
  # names for the aws_guardduty_organization_configuration_feature resource.
  # Add new features to both sides of this map as AWS releases them.
  threat_detection_feature_map = {
    enable_ebs_malware_scanning   = "EBS_MALWARE_PROTECTION"
    enable_eks_protection         = "EKS_AUDIT_LOGS"
    enable_s3_protection          = "S3_DATA_EVENTS"
    enable_lambda_protection      = "LAMBDA_NETWORK_LOGS"
    enable_rds_protection         = "RDS_LOGIN_EVENTS"
    enable_runtime_monitoring     = "RUNTIME_MONITORING"
    enable_eks_runtime_monitoring = "EKS_RUNTIME_MONITORING"
    enable_ai_analyst             = "AI_ANALYST"
  }

  # List of the AWS-side feature names the operator has enabled via
  # security_hub_configuration.threat_detection_features. Absent / false flags
  # produce no entry, so no resource is created for that feature.
  enabled_threat_detection_features = local.enable_guardduty ? [
    for tfvar_key, aws_name in local.threat_detection_feature_map :
    aws_name
    if try(var.security_hub_configuration.threat_detection_features[tfvar_key], false)
  ] : []

  # Some GuardDuty features have `additional_configuration` sub-blocks that AWS
  # populates by default (agent-management for the various runtime monitoring
  # targets, currently all AutoEnable = NONE). If we don't declare them in
  # Terraform, AWS still returns them from describe calls and Terraform sees
  # drift — with additional_configuration being a `forces replacement` field,
  # every apply would destroy + recreate the parent resource. Match AWS state
  # by declaring the sub-blocks (all NONE) for the features that have them.
  # Add entries here when new features are released with sub-config.
  threat_detection_additional_config = {
    RUNTIME_MONITORING = [
      "ECS_FARGATE_AGENT_MANAGEMENT",
      "EC2_AGENT_MANAGEMENT",
      "EKS_ADDON_MANAGEMENT",
    ]
    EKS_RUNTIME_MONITORING = [
      "EKS_ADDON_MANAGEMENT",
    ]
  }

  # Only create the org admin delegation here if Security Hub v1 hasn't already done it.
  # v1 creates aws_securityhub_organization_admin_account when disable_securityhub = false.
  securityhub_v1_managing_org_admin = !try(var.security_services.disable_securityhub, true)
  create_securityhub2_org_admin     = local.enable_securityhub2 && !local.securityhub_v1_managing_org_admin

  payer_account_id    = data.aws_caller_identity.current.account_id
  security_account_id = module.security_account.account_id
  org_resource_id     = aws_organizations_organization.org.id

  # Accounts explicitly opted out of Security Hub 2.0 via security_hubv2_optout = true.
  # The DisableSecurityHubV2 policy is attached directly to each opted-out account,
  # regardless of what the Root has attached. If Root has the enable policy, the direct
  # attachment overrides it for that account. If Root has nothing (unmanaged), the direct
  # attachment explicitly disables that one account. Default is false = do nothing (Root
  # inheritance takes its course).
  securityhub2_opted_out_accounts = local.securityhub2_enabled ? {
    for k, v in var.accounts :
    k => module.accounts[k].account_id
    if try(v.security_hubv2_optout, false)
  } : {}

  # Accounts explicitly opted out of Inspector via inspector_optout = true. Same semantics
  # as securityhub2_opted_out_accounts above.
  inspector_opted_out_accounts = local.securityhub2_enabled ? {
    for k, v in var.accounts :
    k => module.accounts[k].account_id
    if try(v.inspector_optout, false)
  } : {}

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

# Enable Security Hub 2.0 in the security (delegated admin) account, in every enabled
# region. The delegated admin has to have SH v2 turned on locally in each region where
# it's expected to receive findings; if we only created this in the home region and
# relied on the SECURITYHUB_POLICY at Root to propagate enablement to the other regions,
# Terraform state would only track one hub while AWS would have 17 (Gotcha #7). Doing
# it explicitly per-region here makes destroy honest.
resource "aws_securityhub_account_v2" "security_account" {
  for_each = local.enable_securityhub2 ? toset(data.aws_regions.available.names) : toset([])
  provider = aws.security-account
  region   = each.value
}

# Enable Security Hub 2.0 in the payer account.
resource "aws_securityhub_account_v2" "payer_account" {
  count = local.enable_securityhub2 ? 1 : 0
}

# Delegate the security account as the Security Hub 2.0 org administrator.
# Skipped when Security Hub v1 is also enabled (v1's security_hub.tf owns the delegation).
#
# depends_on is intentionally the REVERSE of what you'd naively expect. On DESTROY,
# Terraform reverses the dependency graph — so declaring org_admin as depending on the
# account_v2 resources means org_admin is torn down FIRST when everything is destroyed,
# which is what AWS requires: DisableSecurityHubV2 rejects the call while the account is
# still part of an org managed by an SH policy (and the org_admin registration is what
# marks it as managed). Reference: fooli-media teardown, 2026-07-06.
resource "aws_securityhub_organization_admin_account" "securityhub_v2" {
  count            = local.create_securityhub2_org_admin ? 1 : 0
  admin_account_id = local.security_account_id
  depends_on = [
    aws_securityhub_account_v2.security_account,
    aws_securityhub_account_v2.payer_account,
  ]
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

# ─── Security Hub CSPM (central config + standards policy) ────────────────────
# Turned on by security_hub_configuration.enable_security_hub_cspm = true.
# Deliberately distinct from the legacy resources in security_hub.tf so v1 and
# v2 CSPM configurations do not share state (variables.tf enforces the mutual
# exclusion at plan time via security_services.disable_securityhub = true).
#
# Standard ARNs are provided by the operator via
# security_hub_configuration.security_hub_cspm_enabled_standard_arns. Discover
# the available standards with, from the delegated admin account:
#
#     aws securityhub describe-standards --region <aggregation-region>
#
# AWS recommends enabling the AWS Foundational Security Best Practices (FSBP)
# standard when CSPM is turned on:
#
#     arn:aws:securityhub:<aggregation-region>::standards/aws-foundational-security-best-practices/v/1.0.0

# AWS Central Configuration requires an aws_securityhub_finding_aggregator (v1
# resource, different from aws_securityhub_aggregator_v2) — without it,
# UpdateOrganizationConfiguration returns:
#     ResourceNotFoundException: Finding Aggregator must be created to enable
#     Central Configuration
# Safe alongside the existing aggregator_v2 because AWS treats them as
# separate resources.
resource "aws_securityhub_finding_aggregator" "securityhub_cspm" {
  count        = local.enable_security_hub_cspm ? 1 : 0
  provider     = aws.security-account
  linking_mode = "ALL_REGIONS"

  depends_on = [
    aws_securityhub_account_v2.security_account,
    aws_securityhub_organization_admin_account.securityhub_v2,
  ]
}

resource "aws_securityhub_organization_configuration" "securityhub_cspm" {
  count                 = local.enable_security_hub_cspm ? 1 : 0
  provider              = aws.security-account
  auto_enable           = false
  auto_enable_standards = "NONE"

  organization_configuration {
    configuration_type = "CENTRAL"
  }

  depends_on = [
    aws_securityhub_account_v2.security_account,
    aws_securityhub_organization_admin_account.securityhub_v2,
    aws_securityhub_aggregator_v2.security_account,
    aws_securityhub_finding_aggregator.securityhub_cspm,
  ]
}

resource "aws_securityhub_configuration_policy" "org_kickstart_standards" {
  count       = local.enable_security_hub_cspm ? 1 : 0
  provider    = aws.security-account
  name        = "org_kickstart_standards"
  description = "Org Kickstart baseline Security Hub CSPM standards"
  depends_on  = [aws_securityhub_organization_configuration.securityhub_cspm]

  configuration_policy {
    service_enabled       = true
    enabled_standard_arns = local.security_hub_cspm_enabled_standard_arns
    security_controls_configuration {
      disabled_control_identifiers = []
    }
  }
}

resource "aws_securityhub_configuration_policy_association" "org_kickstart_standards_root" {
  count     = local.enable_security_hub_cspm ? 1 : 0
  provider  = aws.security-account
  target_id = aws_organizations_organization.org.roots[0].id
  policy_id = aws_securityhub_configuration_policy.org_kickstart_standards[0].id
}

# ─── GuardDuty (foundational threat detection) ────────────────────────────────
# Enabled when security_hub_configuration.enable_threat_detection = true. Wired here
# rather than in modules/security_services/ because that module is being deprecated —
# it was a pre-provider-6 workaround for multi-region resources that the AWS provider
# now handles natively via the `region` argument.
#
# Three resources per region:
#   1. Detector in the security account (delegated admin needs a local hub in each
#      region to receive findings).
#   2. GuardDuty delegated admin registration from the payer (designates the security
#      account as the org GD admin in that region).
#   3. Organization configuration on the security account, with auto_enable = "ALL" so
#      every existing and future org account gets a detector automatically. This is
#      the piece the SH v2 console "deployment" flow does NOT do — hence the console's
#      infuriating "will not turn on the capability for future accounts" warning.

resource "aws_guardduty_detector" "security_account" {
  for_each = local.enable_guardduty ? toset(data.aws_regions.available.names) : toset([])
  provider = aws.security-account
  region   = each.value
  enable   = true
}

resource "aws_guardduty_organization_admin_account" "security_account" {
  for_each         = local.enable_guardduty ? toset(data.aws_regions.available.names) : toset([])
  region           = each.value
  admin_account_id = local.security_account_id
  depends_on       = [aws_guardduty_detector.security_account]
}

resource "aws_guardduty_organization_configuration" "security_account" {
  for_each                         = local.enable_guardduty ? toset(data.aws_regions.available.names) : toset([])
  provider                         = aws.security-account
  region                           = each.value
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.security_account[each.key].id
  depends_on                       = [aws_guardduty_organization_admin_account.security_account]
}

# Extended GuardDuty features (S3 protection, EKS audit logs, RDS login events, etc.).
# One resource per (feature × region). Each feature the operator sets to true in
# security_hub_configuration.threat_detection_features gets an AutoEnable = ALL org
# configuration entry, so new members get the feature turned on automatically.
# Existing members that were previously disassociated still need the one-shot enrollment
# helper — see scripts/enroll_guardduty_members.py (pending).
resource "aws_guardduty_organization_configuration_feature" "security_account" {
  for_each = {
    for pair in setproduct(local.enabled_threat_detection_features, tolist(toset(data.aws_regions.available.names))) :
    "${pair[0]}:${pair[1]}" => { feature = pair[0], region = pair[1] }
  }

  provider    = aws.security-account
  region      = each.value.region
  detector_id = aws_guardduty_detector.security_account[each.value.region].id
  name        = each.value.feature
  auto_enable = "ALL"

  # AWS populates additional_configuration sub-blocks by default for features that
  # have them (currently only the two runtime-monitoring flavors). Declare them
  # here — all AutoEnable = NONE — so Terraform's view matches AWS's and doesn't
  # attempt to remove them on every plan (which would force replacement).
  dynamic "additional_configuration" {
    for_each = lookup(local.threat_detection_additional_config, each.value.feature, [])
    content {
      name        = additional_configuration.value
      auto_enable = "NONE"
    }
  }

  depends_on = [aws_guardduty_organization_configuration.security_account]
}

# Security Hub and Inspector org policies are one-shot: detaching an "enable" policy does
# NOT disable the service — you must explicitly attach a "disable" policy to reverse it.
# We therefore always create both the enable and the disable policy for each service (as
# long as security_hub_configuration is present), so operators can flip between them
# without policy-creation churn. Which one is attached to Root is controlled by the
# enable_*_for_all_accounts flags (tri-state: true/false/absent).

# SECURITYHUB_POLICY enable — Security Hub 2.0 in all regions for all accounts.
resource "aws_organizations_policy" "securityhub_enable" {
  count       = local.securityhub2_enabled ? 1 : 0
  name        = "EnableSecurityHubV2"
  description = "Enable Security Hub 2.0 in all regions for all accounts"
  type        = "SECURITYHUB_POLICY"
  content     = file("${path.module}/policies/SecurityHubEnable_OrgPolicy.json")
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_organizations_policy_attachment" "securityhub_enable_root" {
  count     = local.sechub_root_action == true ? 1 : 0
  policy_id = aws_organizations_policy.securityhub_enable[0].id
  target_id = tolist(aws_organizations_organization.org.roots)[0].id
  # Race guard: the moment this attachment lands, AWS starts propagating the SECURITYHUB_POLICY
  # across every account × every region. Anything that isn't already set up when propagation
  # fires will lose a race and error out — most famously, concurrent EnableSecurityHubV2 calls
  # get rejected with "Account is part of an AWS Organization and is being managed by a
  # Security Hub policy." So this attachment happens LAST, after every piece of SH v2
  # infrastructure the policy will start managing has been created.
  # Reference: fooli-media re-enable attempt, 2026-07-07.
  depends_on = [
    aws_securityhub_account_v2.security_account,
    aws_securityhub_account_v2.payer_account,
    aws_securityhub_organization_admin_account.securityhub_v2,
    aws_securityhub_aggregator_v2.security_account,
    aws_organizations_resource_policy.organization_resource_policy,
    aws_iam_role_policy.securityhub_cost_estimator,
    aws_organizations_policy_attachment.securityhub_disable_account,
  ]
}

# INSPECTOR_POLICY enable — Amazon Inspector scanning (Lambda standard, Lambda code, EC2,
# ECR, code repository) in all regions for all accounts.
resource "aws_organizations_policy" "inspector_enable" {
  count       = local.securityhub2_enabled ? 1 : 0
  name        = "EnableInspector"
  description = "Enable Amazon Inspector scanning in all regions for all accounts"
  type        = "INSPECTOR_POLICY"
  content     = file("${path.module}/policies/SecHubEnableInspector_OrgPolicy.json")
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_organizations_policy_attachment" "inspector_enable_root" {
  count     = local.inspector_root_action == true ? 1 : 0
  policy_id = aws_organizations_policy.inspector_enable[0].id
  target_id = tolist(aws_organizations_organization.org.roots)[0].id
  # Same "attach root policies LAST" pattern as securityhub_enable_root. Inspector's
  # propagation uses the same org delegated admin machinery, so wait for the whole SH v2
  # foundation to be in place before firing the policy.
  depends_on = [
    aws_securityhub_account_v2.security_account,
    aws_securityhub_account_v2.payer_account,
    aws_securityhub_organization_admin_account.securityhub_v2,
    aws_securityhub_aggregator_v2.security_account,
    aws_organizations_resource_policy.organization_resource_policy,
    aws_iam_role_policy.securityhub_cost_estimator,
    aws_organizations_policy_attachment.inspector_disable_account,
  ]
}

# SECURITYHUB_POLICY disable — always created when security_hub_configuration is present.
# Attached to Root when enable_security_hub_for_all_accounts = false, and/or to any
# individual accounts that set enable_security_hubv2 = false while the root enable policy
# is attached.
resource "aws_organizations_policy" "securityhub_disable" {
  count       = local.securityhub2_enabled ? 1 : 0
  name        = "DisableSecurityHubV2"
  description = "Disable Security Hub 2.0. Attach at Root or to specific accounts."
  type        = "SECURITYHUB_POLICY"
  content = jsonencode({
    securityhub = {
      enable_in_regions = {
        "@@assign" = []
      }
      disable_in_regions = {
        "@@assign" = ["ALL_SUPPORTED"]
      }
    }
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_organizations_policy_attachment" "securityhub_disable_root" {
  count     = local.sechub_root_action == false ? 1 : 0
  policy_id = aws_organizations_policy.securityhub_disable[0].id
  target_id = tolist(aws_organizations_organization.org.roots)[0].id
  # Same "attach root policies LAST" pattern. Even for the disable path, if some SH v2
  # resource is still being created concurrently, the propagation will race with it.
  depends_on = [
    aws_securityhub_account_v2.security_account,
    aws_securityhub_account_v2.payer_account,
    aws_securityhub_organization_admin_account.securityhub_v2,
    aws_securityhub_aggregator_v2.security_account,
    aws_organizations_resource_policy.organization_resource_policy,
    aws_iam_role_policy.securityhub_cost_estimator,
  ]
}

resource "aws_organizations_policy_attachment" "securityhub_disable_account" {
  for_each  = local.securityhub2_opted_out_accounts
  policy_id = aws_organizations_policy.securityhub_disable[0].id
  target_id = each.value
}

# INSPECTOR_POLICY disable — always created when security_hub_configuration is present.
# Attached to Root when enable_inspector_for_all_accounts = false, and/or to any individual
# accounts that set enable_inspector = false while the root enable policy is attached.
resource "aws_organizations_policy" "inspector_disable" {
  count       = local.securityhub2_enabled ? 1 : 0
  name        = "DisableInspector"
  description = "Disable Amazon Inspector. Attach at Root or to specific accounts."
  type        = "INSPECTOR_POLICY"
  content = jsonencode({
    inspector = {
      enablement = {
        lambda_standard_scanning = {
          enable_in_regions  = { "@@assign" = [] }
          disable_in_regions = { "@@assign" = ["ALL_SUPPORTED"] }
          lambda_code_scanning = {
            enable_in_regions  = { "@@assign" = [] }
            disable_in_regions = { "@@assign" = ["ALL_SUPPORTED"] }
          }
        }
        ec2_scanning = {
          enable_in_regions  = { "@@assign" = [] }
          disable_in_regions = { "@@assign" = ["ALL_SUPPORTED"] }
        }
        ecr_scanning = {
          enable_in_regions  = { "@@assign" = [] }
          disable_in_regions = { "@@assign" = ["ALL_SUPPORTED"] }
        }
        code_repository_scanning = {
          enable_in_regions  = { "@@assign" = [] }
          disable_in_regions = { "@@assign" = ["ALL_SUPPORTED"] }
        }
      }
    }
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_organizations_policy_attachment" "inspector_disable_root" {
  count     = local.inspector_root_action == false ? 1 : 0
  policy_id = aws_organizations_policy.inspector_disable[0].id
  target_id = tolist(aws_organizations_organization.org.roots)[0].id
  # Same "attach root policies LAST" pattern.
  depends_on = [
    aws_securityhub_account_v2.security_account,
    aws_securityhub_account_v2.payer_account,
    aws_securityhub_organization_admin_account.securityhub_v2,
    aws_securityhub_aggregator_v2.security_account,
    aws_organizations_resource_policy.organization_resource_policy,
    aws_iam_role_policy.securityhub_cost_estimator,
  ]
}

resource "aws_organizations_policy_attachment" "inspector_disable_account" {
  for_each  = local.inspector_opted_out_accounts
  policy_id = aws_organizations_policy.inspector_disable[0].id
  target_id = each.value
}

