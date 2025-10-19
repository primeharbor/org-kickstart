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
  type        = map(string)
  default     = {}
}

#
# Core Accounts
#
variable "security_account_root_email" {
  description = "Root Email address for the security account"
  type        = string
}
variable "security_account_name" {
  description = "Name of the Security Account"
  type        = string
  default     = "Security Account"
}

variable "payer_email" {
  description = "Root Email address for the Organization Management account"
  type        = string
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
  description = "Set to true to disable creating a default Admin Permission Set in Identity Center."
  type        = bool
  default     = false
}
variable "session_duration" {
  description = "Admin Permission Set Session Duration"
  type        = string
  default     = "PT8H"

  validation {
    # Regex taken from https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sso-permissionset.html#cfn-sso-permissionset-sessionduration and modified to use HCL2 compatible syntax
    condition     = can(regex("^P(?:(\\d+Y)?(\\d+M)?(\\d+D)?(T(\\d+H)?(\\d+M)?(\\d+S)?)?)$", var.session_duration))
    error_message = "Session duration must use the ISO8601 duration format. ${var.session_duration} isn't a valid duration string"
  }
}
variable "admin_permission_set_name" {
  description = "Name of the Default Admin Permission Set to Create"
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
  description = "Name of the S3 Bucket to create to store CloudTrail events. Set to null to disable CloudTrail management"
  type        = string
  default     = null
}
variable "cloudtrail_loggroup_name" {
  description = "Name of the CloudWatch Log Group in the payer account where CloudTrail will send its events. Set to null to disable CloudTrail to CloudWatch Logs."
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
variable "accounts" {
  description = "AWS accounts to provision in the organization. "
  type = map(
    object({
      account_name    = string
      account_email   = string
      delegated_admin = optional(list(string), [])
      operations_contact = optional(object({
        name          = string
        title         = string
        email_address = string
        phone_number  = string
      }))
      primary_contact = optional(object({
        full_name          = string
        company_name       = optional(string)
        address_line_1     = string
        address_line_2     = optional(string)
        address_line_3     = optional(string)
        city               = string
        district_or_county = optional(string)
        state_or_region    = optional(string)
        postal_code        = string
        country_code       = string
        phone_number       = string
        website_url        = optional(string)
      }))
      # parent_ou_id can explicitly override the OU assignment and lookup by name.
      # parent_ou_id takes precedence over parent_ou_name
      parent_ou_name            = optional(string, "Workloads")
      parent_ou_id              = optional(string, null)
      monthly_budget_amount     = optional(number, 0)
      budget_alert_recipients   = optional(list(string), [])
      service_control_policies  = optional(list(string), [])
      resource_control_policies = optional(list(string), [])
      declarative_policies_ec2  = optional(list(string), [])
    })
  )
}

variable "security_account" {
  description = "Settings for the Security Account."
  type = object({
    # These will move from the main module to here at some point.
    # account_name    = string
    # account_email   = string
    delegated_admin = optional(list(string), [])
    operations_contact = optional(object({
      name          = string
      title         = string
      email_address = string
      phone_number  = string
    }))
    primary_contact = optional(object({
      full_name          = string
      company_name       = optional(string)
      address_line_1     = string
      address_line_2     = optional(string)
      address_line_3     = optional(string)
      city               = string
      district_or_county = optional(string)
      state_or_region    = optional(string)
      postal_code        = string
      country_code       = string
      phone_number       = string
      website_url        = optional(string)
    }))
    monthly_budget_amount   = optional(number, 0)
    budget_alert_recipients = optional(list(string), [])
  })

}

variable "account_configurator" {
  description = "Serverless Application to configure new accounts. See https://github.com/primeharbor/pht-account-configurator"
  default     = null
  type = object({
    account_factory_config_file = string
    template                    = string
  })
}
variable "backend_bucket" {
  description = "Name of the S3 bucket used for the CloudFormation stacks and Terraform state backend"
  type        = string
}


#
# Account Contacts
#
variable "global_billing_contact" {
  description = "Billing alternate contact to be applied to all accounts."
  default     = null
  type = object({
    name          = string
    title         = string
    email_address = string
    phone_number  = string
  })
}
variable "global_security_contact" {
  description = "Security alternate contact to be applied to all accounts"
  default     = null
  type = object({
    name          = string
    title         = string
    email_address = string
    phone_number  = string
  })
}
variable "global_operations_contact" {
  description = "Default operations alternate contact to be applied to all accounts. Can be overridden in account definition."
  default     = null
  type = object({
    name          = string
    title         = string
    email_address = string
    phone_number  = string
  })
}
variable "global_primary_contact" {
  description = "Default primary account owner to be applied to all accounts. Can be overridden in account definition."
  default     = null
  type = object({
    full_name          = string
    company_name       = optional(string)
    address_line_1     = string
    address_line_2     = optional(string)
    address_line_3     = optional(string)
    city               = string
    district_or_county = optional(string)
    state_or_region    = optional(string)
    postal_code        = string
    country_code       = string
    phone_number       = string
    website_url        = optional(string)
  })
}

#
# Billing
#
variable "billing_data_bucket_name" {
  description = "Name of the S3 Bucket for CUR reports. Set to null to disable CUR report generation."
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

variable "billing_alerts" {
  description = "Triggers for billing alerts and who should receive them."
  type = object({
    levels        = map(number)
    subscriptions = list(string)
  })
  default = null
}

variable "budget_defaults" {
  description = "Default values for AWS Budgets. Some settings can be overridden in the account definition."
  type = object({
    alert_recipients      = optional(list(string), [])
    currency              = optional(string, "USD")
    warning_percentage    = optional(number, 85)
    organizational_budget = optional(number, 0)
  })

  default = {}
}

#
# SCPs & OUs
variable "service_control_policies" {
  description = "Map of SCPs to create and attach."
  default     = {}
  type = map(
    object({
      policy_name        = string
      policy_description = string
      policy_json_file   = string
      policy_targets     = optional(list(string), ["Root"])
      policy_vars        = optional(map(string), {})
      do_not_attach      = optional(bool, false)
    })
  )
}

variable "resource_control_policies" {
  description = "Map of RCPs to create and attach."
  default     = {}
  type = map(
    object({
      policy_name        = string
      policy_description = string
      policy_json_file   = string
      policy_targets     = optional(list(string), ["Root"])
      policy_vars        = optional(map(string), {})
      do_not_attach      = optional(bool, false)
    })
  )
}

variable "organization_units" {
  description = "Map of OUs to create."
  default     = {}
  type = map(
    object({
      name             = string
      is_child_of_root = optional(bool) # This is ignored, it is retained for backwards compatibility
      parent_id        = optional(string)
    })
  )
}

variable "declarative_policy_bucket_name" {
  description = "Name of S3 Bucket for Declarative Policy Reports. Set to null to disable Declarative Policy Reports."
  default     = null
  type        = string
}

variable "declarative_policies" {
  description = "Map of Declarative Policies to create and attach."
  default     = {}
  type = map(object({
    policy_name        = string
    policy_description = string
    policy_json_file   = string
    policy_targets     = optional(list(string), ["Root"])
    policy_vars        = optional(map(string), {})
    do_not_attach      = optional(bool, false)
  }))
}

variable "aws_service_access_principals_to_exclude" {
  description = "List of AWS service access principals to exclude from the default set."
  type        = list(string)
  default     = []
}

variable "aws_service_access_principals_to_enable" {
  description = "List of AWS service access principals to enable if they're not part of the default set."
  type        = list(string)
  default     = []
}

variable "organization_policy_types_to_exclude" {
  description = "List of organization policy types to exclude from the default set."
  type        = list(string)
  default     = []
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
  description = "Boolean to determine if org-kickstart should manage a Security Audit Role. Set to false to disable the creation of an Audit Role stackset."
  type        = bool
  default     = true
}

#
# Security Service flags
variable "security_services" {
  description = "Explicitly disable or not manage a security service"
  type = object({
    disable_guardduty   = optional(bool, false)
    disable_macie       = optional(bool, false)
    disable_inspector   = optional(bool, false)
    disable_securityhub = optional(bool, false)
    disable_stacksets   = optional(bool, false)
  })
}

variable "default_close_on_deletion" {
  description = "If set, the AWS Account will be closed when it's removed from org-kickstart. Set this with caution."
  default     = false
  type        = bool
}

variable "datatrail" {
  description = "Details on the DataTrails"
  default     = null
  type = object({
    bucket_name      = string
    trail_name       = string
    enabled          = optional(bool, true)
    excluded_buckets = list(string)
  })
}
