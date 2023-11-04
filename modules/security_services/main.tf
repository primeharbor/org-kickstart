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
      source                = "hashicorp/aws"
      version               = ">= 2.7.0"
      configuration_aliases = [aws.security_account, aws.payer_account]
    }
  }
}

variable "security_account_id" {}

variable "disable_guardduty" {
  default = false
}
variable "disable_macie" {
  default = false
}
variable "disable_inspector" {
  default = false
}
variable "disable_securityhub" {
  default = false
}


data "aws_organizations_organization" "org" {}
data "aws_organizations_organizational_unit_descendant_accounts" "accounts" {
  provider  = aws.security_account
  parent_id = data.aws_organizations_organization.org.roots[0].id
}