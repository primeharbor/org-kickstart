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

#
# CloudTrail
#
variable "cloudtrail_bucket_name" {
  description = "Name of the S3 Bucket to create to store CloudTrail events"
  type        = string
  default     = null
}


#
# Account Index
#
variable "accounts" {}
variable "global_billing_contact" {
  description = "Map for the central billing contact to be applied to all accounts"
  default     = null
}
variable "global_security_contact" {
  description = "Map for the central security contact to be applied to all accounts"
  default     = null
}


#
# Billing
#
variable "billing_data_bucket_name" {
  description = "Name of the S3 Bucket for CUR reports"
  type        = string
  default     = null
}

variable "cur_report_frequency" {
  description = "Frequency CUR reports should be delivered (DAILY, HOURLY, MONTHLY)"
  type        = string
  default     = "null"

  validation {
    condition     = can(regex("^(DAILY|HOURLY|MONTHLY|null)$", var.cur_report_frequency))
    error_message = "Valid options: DAILY, HOURLY, MONTHLY"
  }

}


#
# SCPs
variable "service_control_policies" {
  description = "Map of SCPs to deploy"
}

