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

variable "account_name" {
  description = "Name of the AWS Account to Create"
  type        = string
}

variable "account_email" {
  description = "Root Email Address to Create"
  type        = string
}

variable "parent_ou_id" {
  description = "ID of the Parent OU"
  type        = string
}

variable "admin_permission_set_arn" {
  description = "Arn of the Identity Center Permission Set"
  type        = string
}

variable "admin_group_id" {
  description = "ID of the Identity Center Admin Group"
  type        = string
}

variable "billing_contact" {
  description = "The Billing Alternate Contact to apply to this account."
  default     = null
}
variable "security_contact" {
  description = "The Security Alternate Contact to apply to this account."
  default     = null
}
variable "operations_contact" {
  description = "The Operations Alternate Contact to apply to this account."
  default     = null
}
variable "primary_contact" {
  description = "The Primary Contact / Account Owner to apply to this account."
  default     = null
}

variable "delegated_admin" {
  description = "List of AWS Services that this account is a delegated administrator for"
  type        = set(string)
  default     = []
}

variable "disable_sso_management" {
  default     = false
  description = "If set, the default SSO assignment won't be applied to this account"
  type        = bool
}

variable "default_close_on_deletion" {
  description = "If set, the AWS Account will be closed when it's removed from org-kickstart. Set this with caution"
  default     = false
  type        = bool
}

variable "service_control_policies" {
  description = "List of SCP Names that are directly applied to this AWS Account. Policies must be created before they can be referenced."
  default     = []
  type        = list(string)
}

variable "resource_control_policies" {
  description = "List of RCP Names that are directly applied to this AWS Account. Policies must be created before they can be referenced."
  default     = []
  type        = list(string)
}

variable "declarative_policies_ec2" {
  description = "List of Declarative Policy Names that are directly applied to this AWS Account. Policies must be created before they can be referenced."
  default     = []
  type        = list(string)
}

variable "scp_name_to_id_map" {
  description = "Lookup table of SCPs by their name"
}
variable "rcp_name_to_id_map" {
  description = "Lookup table of RCPs by their name"
}
variable "dp_ec2_name_to_id_map" {
  description = "Lookup table of EC2 Decalarative Policies by their name"
}

variable "sso_instance_region" {
  type        = string
  default     = "us-east-1"
  description = "Region where the AWS SSO instance is configured"
}

resource "aws_organizations_account" "account" {
  name              = var.account_name
  email             = var.account_email
  parent_id         = var.parent_ou_id
  close_on_deletion = var.default_close_on_deletion
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_organizations_delegated_administrator" "delegated_admin" {
  for_each          = var.delegated_admin
  account_id        = aws_organizations_account.account.id
  service_principal = each.value
}

output "account_id" {
  value = aws_organizations_account.account.id
}