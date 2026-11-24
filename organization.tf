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
# Define the Organization & enable services
#
# Default service setup with what makes sense.

locals {
  default_aws_service_access_principals = [
    "access-analyzer.amazonaws.com",
    "account.amazonaws.com",
    "aws-artifact-account-sync.amazonaws.com",
    "backup.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "compute-optimizer.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "config.amazonaws.com",
    "cost-optimization-hub.bcm.amazonaws.com",
    "ec2.amazonaws.com",
    "fms.amazonaws.com",
    "guardduty.amazonaws.com",
    "health.amazonaws.com",
    "iam.amazonaws.com",
    "inspector2.amazonaws.com",
    "ipam.amazonaws.com",
    "license-management.marketplace.amazonaws.com",
    "license-manager.amazonaws.com",
    "license-manager.member-account.amazonaws.com",
    "macie.amazonaws.com",
    "malware-protection.guardduty.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "notifications.amazonaws.com",
    "ram.amazonaws.com",
    "reporting.trustedadvisor.amazonaws.com",
    "resource-explorer-2.amazonaws.com",
    "securityhub.amazonaws.com",
    "servicequotas.amazonaws.com",
    "ssm.amazonaws.com",
    "sso.amazonaws.com",
    "storage-lens.s3.amazonaws.com",
    "tagpolicies.tag.amazonaws.com",
  ]

  default_enabled_policy_types = [
    "AISERVICES_OPT_OUT_POLICY",
    "BACKUP_POLICY",
    "BEDROCK_POLICY",
    "CHATBOT_POLICY",
    "DECLARATIVE_POLICY_EC2",
    "INSPECTOR_POLICY",
    "RESOURCE_CONTROL_POLICY",
    "S3_POLICY",
    "SECURITYHUB_POLICY",
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "UPGRADE_ROLLOUT_POLICY"
  ]

  merged_aws_service_access_principals = distinct(
    concat(
      local.default_aws_service_access_principals,
      var.aws_service_access_principals_to_enable
    )
  )

  filtered_aws_service_access_principals = [
    for principal in local.merged_aws_service_access_principals :
    principal if !(contains(var.aws_service_access_principals_to_exclude, principal))
  ]

  filtered_enabled_policy_types = [
    for policy in local.default_enabled_policy_types :
    policy if !(contains(var.organization_policy_types_to_exclude, policy))
  ]
}


# Create the organization
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = local.filtered_aws_service_access_principals
  enabled_policy_types          = local.filtered_enabled_policy_types
  feature_set                   = "ALL"
}

# Enable management of root credentials
resource "aws_iam_organizations_features" "org" {
  depends_on = [aws_organizations_organization.org]
  enabled_features = [
    "RootCredentialsManagement",
    "RootSessions"
  ]
}

# Leverage data vs the resource so things don't un-necessarily change when updating the org.
data "aws_organizations_organization" "org" {}

# Enable resource sharing within the org without the need for invites.
# Depends on the org explicitly so it doesn't race org creation on first apply.
resource "aws_ram_sharing_with_organization" "enable" {
  depends_on = [aws_organizations_organization.org]
}

# Organization resource policy. Delegated admin accounts need explicit permission to
# read and manage org-level resources. Each service that requires org-level delegation
# contributes statements via locals defined in its own .tf file (e.g. security_hub_2.tf).
# The resource is created only when at least one set of delegation statements is present.
resource "aws_organizations_resource_policy" "organization_resource_policy" {
  count = local.create_org_policy ? 1 : 0

  content = jsonencode({
    Version   = "2012-10-17"
    Statement = local.org_delegation_statements
  })

  # The Organizations API rejects tag updates on existing resource policies.
  lifecycle {
    ignore_changes = [tags_all]
  }
}
