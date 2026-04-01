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

output "accounts" {
  description = "Map of account names to account IDs"
  value = merge(
    { payer = aws_organizations_account.payer.id, security = module.security_account.account_id },
    { for name, account in module.accounts : name => account.account_id }
  )
}

output "account_map" {
  description = "Map of account names (actual names, not terraform keys) to account IDs"
  value = merge(
    {
      (aws_organizations_account.payer.name) = aws_organizations_account.payer.id,
      (module.security_account.account_name) = module.security_account.account_id
    },
    { for name, account in module.accounts : account.account_name => account.account_id }
  )
}

output "declarative_policy_bucket" {
  description = "S3 Bucket used to store declarative policies"
  value       = var.declarative_policy_bucket_name != null ? aws_s3_bucket.declarative_policy_bucket[0].id : null
}

output "macie_key_arn" {
  description = "ARN of the KMS Key used by Macie"
  value       = var.macie_bucket_name == null ? null : aws_kms_key.macie_key[0].arn
}

output "org_id" {
  description = "ID of the AWS Organization"
  value       = data.aws_organizations_organization.org.id
}

output "org_name" {
  description = "Name of the AWS Organization"
  value       = var.organization_name
}

output "ou_name_to_id" {
  description = "Map of OU Names to OU IDs"
  value       = local.ou_name_to_id
}

output "security_account_id" {
  description = "ID of the Security Account"
  value       = module.security_account.account_id
}

output "sso_instance_arn" {
  description = "AWS Identity Center Instance ARN managed by org-kickstart"
  value       = tolist(data.aws_ssoadmin_instances.identity_store.arns)[0]
}

output "sso_role_name" {
  description = "Name of the SSO Permission Set (role name) for admin access"
  value       = var.disable_sso_management ? null : var.admin_permission_set_name
}

output "sso_region" {
  description = "AWS Region where SSO Identity Center is configured"
  value       = var.sso_instance_region
}

output "sso_start_url" {
  description = "AWS SSO start URL (e.g., https://yourorg.awsapps.com/start)"
  value       = var.sso_start_url
}
