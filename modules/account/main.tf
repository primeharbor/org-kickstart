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
  default = null
}
variable "security_contact" {
  default = null
}
variable "operations_contact" {
  default = null
}
variable "primary_contact" {
  default = null
}

variable "preserve_root" {
  default = false
}


variable "disable_sso_management" {
  type = bool
}

resource "aws_organizations_account" "account" {
  name      = var.account_name
  email     = var.account_email
  parent_id = var.parent_ou_id
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


output "account_id" {
  value = aws_organizations_account.account.id
}