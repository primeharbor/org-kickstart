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

variable "organization_name" {
  description = "Name of the Organization. This is used for resource prefixes and general reference"
  type        = string
}

variable "tag_set" {
  description = "Default map of tags to be applied to all resources via all providers"
  type        = map(any)
  default     = {}
}

#
# Core Accounts
#
variable "security_account_root_email" {
  description = "Root Email address for the security account"
  type        = string
  default     = null
}
variable "security_account_name" {
  description = "Name of the Security Account"
  type        = string
  default     = "Security Account"
}

variable "payer_email" {
  description = "Root Email address for the Organization Management account"
  type        = string
  default     = null
}
variable "payer_name" {
  description = "Name of the Organization Management account"
  type        = string
  default     = "AWS Payer"
}


#
# SSO
#
variable "disable_sso_management" {
  description = "Set to true to manage AWS Identity Center outside of org-kickstart"
  type        = bool
  default     = false
}
variable "session_duration" {
  description = "Default Session Duration"
  type        = string
  default     = "PT8H"
}
variable "admin_permission_set_name" {
  description = "Name of the Permission Set to Create"
  type        = string
  default     = "AdministratorAccess"
}
variable "admin_group_name" {
  description = "Name of the Identity Store Group with all the admin users"
  type        = string
  default     = "AllAdmins"
}

#
# CloudTrail
#
variable "cloudtrail_bucket_name" {
  description = "Name of the S3 Bucket to create to store CloudTrail events. Set to null to disable cloudtrail management"
  type        = string
  default     = null
}
variable "cloudtrail_loggroup_name" {
  description = "Name of the CloudWatch Log Group in the payer account where CloudTrail will send its events"
  type        = string
  default     = null
}

# VPC Flowlog Bucket
variable "vpc_flowlogs_bucket_name" {
  description = "Name of the S3 Bucket to create to store VPC Flow Logs. Set to null to skip creation"
  type        = string
  default     = null
}

# Macie Bucket
variable "macie_bucket_name" {
  description = "Name of the S3 Bucket to create to store Macie Findings. Set to null to skip creation"
  type        = string
  default     = null
}



#
# Account Index
#
variable "accounts" {}

variable "account_configurator" {
  default = null
}
variable "backend_bucket" {}

variable "billing_alerts" {
  default = null
}

#
# Account Contacts
#
variable "global_billing_contact" {
  description = "Map for the central billing alternate contact to be applied to all accounts"
  default     = null
}
variable "global_security_contact" {
  description = "Map for the central security alternate contact to be applied to all accounts"
  default     = null
}
variable "global_operations_contact" {
  description = "Map for the central operations alternate contact to be applied to all accounts"
  default     = null
}
variable "global_primary_contact" {
  description = "Map for the primary account owner to be applied to all accounts"
  default     = null
}

#
# Billing
#
variable "billing_data_bucket_name" {
  description = "Name of the S3 Bucket for CUR reports. Set to null to disable"
  type        = string
  default     = null
}

variable "cur_report_frequency" {
  description = "Frequency CUR reports should be delivered (DAILY, HOURLY, MONTHLY). Set to NONE to disable"
  type        = string
  default     = "NONE"

  validation {
    condition     = can(regex("^(DAILY|HOURLY|MONTHLY|NONE)$", var.cur_report_frequency))
    error_message = "Valid options: DAILY, HOURLY, MONTHLY, NONE"
  }

}

#
# SCPs & OUs
variable "service_control_policies" {
  description = "Map of SCPs to deploy"
  default     = {}
}

variable "resource_control_policies" {
  description = "Map of RCPs to deploy"
  default     = {}
}

variable "organization_units" {
  description = "Map of OUs to deploy"
  default     = {}
}

variable "declarative_policy_bucket_name" {
  description = "Name of S3 Bucket for Declarative Policy Reports"
  default     = null
}

variable "declarative_policies" {
  description = "Map of Declarative Policies to deploy"
  default     = {}
}

#
# Audit Role
#
variable "audit_role_name" {
  description = "Name of the AuditRole to deploy"
  default     = "security-audit"
  type        = string
}

variable "audit_role_stack_set_template_url" {
  description = "URL that points to the Audit Role Policy Template"
  default     = null
  type        = string
}

variable "deploy_audit_role" {
  description = "Boolean to determine if org-kickstart should manage Audit Role"
  type        = bool
  default     = true
}
