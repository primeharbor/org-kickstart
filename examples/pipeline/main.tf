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

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.14.9"

  # This is configured in the $env.backend file
  backend "s3" {
    region = "us-east-1"
  }
}

locals {
  default_tags = {
    managed_by = "org-kickstart"
    tf_repo    = "CHANGEME"
  }
}

module "organization" {

  # Use the latest
  source = "github.com/primeharbor/org-kickstart"

  # Pin to a specific release
  # source = "github.com/primeharbor/org-kickstart?ref=v0.0.1"

  tag_set        = local.default_tags
  backend_bucket = var.backend_bucket

  # Organization Names
  organization_name           = var.organization["organization_name"]
  security_account_root_email = var.organization["security_account_root_email"]
  security_account_name       = var.organization["security_account_name"]
  payer_email                 = var.organization["payer_email"]
  payer_name                  = var.organization["payer_name"]

  # SSO
  session_duration          = lookup(var.organization, "session_duration", "PT8H")
  admin_permission_set_name = lookup(var.organization, "admin_permission_set_name", "AdministratorAccess")
  admin_group_name          = lookup(var.organization, "admin_group_name", "AllAdmins")
  disable_sso_management    = lookup(var.organization, "disable_sso_management", false)

  # Audit Role
  deploy_audit_role = lookup(var.organization, "deploy_audit_role", true)
  audit_role_name   = lookup(var.organization, "audit_role_name", "security-audit")

  # CloudTrail
  cloudtrail_bucket_name   = lookup(var.organization, "cloudtrail_bucket_name", null)
  cloudtrail_loggroup_name = lookup(var.organization, "cloudtrail_loggroup_name", null)

  # Map Objects
  accounts                  = lookup(var.organization, "accounts", {})
  service_control_policies  = lookup(var.organization, "service_control_policies", {})
  resource_control_policies = lookup(var.organization, "resource_control_policies", {})
  declarative_policies      = lookup(var.organization, "declarative_policies", {})
  organization_units        = lookup(var.organization, "organization_units", {})
  account_configurator      = lookup(var.organization, "account_configurator", null)
  billing_alerts            = lookup(var.organization, "billing_alerts", null)

  # Global Alternate Contacts
  global_billing_contact    = lookup(var.organization, "global_billing_contact", null)
  global_security_contact   = lookup(var.organization, "global_security_contact", null)
  global_operations_contact = lookup(var.organization, "global_operations_contact", null)
  global_primary_contact    = lookup(var.organization, "global_primary_contact", null)

  # Billing CUR Reports
  billing_data_bucket_name = lookup(var.organization, "billing_data_bucket_name", null)
  cur_report_frequency     = lookup(var.organization, "cur_report_frequency", "NONE")

  # Security Stuff
  security_services              = lookup(var.organization, "security_services", {})
  vpc_flowlogs_bucket_name       = lookup(var.organization, "vpc_flowlogs_bucket_name", null)
  macie_bucket_name              = lookup(var.organization, "macie_bucket_name", null)
  declarative_policy_bucket_name = lookup(var.organization, "declarative_policy_bucket_name", null)
}

variable "organization" {}
variable "backend_bucket" {}

output "org_name" {
  value = module.organization.org_name
}

output "org_id" {
  value = module.organization.org_id
}

output "security_account_id" {
  value = module.organization.security_account_id
}

output "sso_instance_arn" {
  value = module.organization.sso_instance_arn
}

output "declarative_policy_bucket" {
  value = module.organization.declarative_policy_bucket
}