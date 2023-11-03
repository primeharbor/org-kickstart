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

#
# Create Provider for Management Account
#
provider "aws" {
  region = "us-east-1"

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#default_tags
  default_tags {
    tags = {
      managed_by = "pht-org-kickstart"
    }
  }

}

#
# Create Provider for Security Account
#
provider "aws" {
  alias  = "security_account"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::${module.organization.security_account_id}:role/OrganizationAccountAccessRole"
  }

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#default_tags
  default_tags {
    tags = {
      managed_by = "pht-org-kickstart"
    }
  }
}

module "organization" {
  source = "github.com/primeharbor/org-kickstart"
  providers = {
    aws                  = aws
    aws.security_account = aws.security_account
  }
  organization_name           = var.organization["organization_name"]
  security_account_root_email = var.organization["security_account_root_email"]
  security_account_name       = var.organization["security_account_name"]
  payer_email                 = var.organization["payer_email"]
  payer_name                  = var.organization["payer_name"]
  session_duration            = var.organization["session_duration"]
  admin_permission_set_name   = var.organization["admin_permission_set_name"]
  cloudtrail_bucket_name      = var.organization["cloudtrail_bucket_name"]
  accounts                    = var.organization["accounts"]
  service_control_policies    = var.organization["service_control_policies"]
  global_billing_contact      = var.organization["global_billing_contact"]
  # global_security_contact = var.organization["global_security_contact"]
  billing_data_bucket_name = var.organization["billing_data_bucket_name"]
  cur_report_frequency     = var.organization["cur_report_frequency"]
}

variable "organization" {}

output "org_name" {
  value = module.organization.org_name
}

output "security_account_id" {
  value = module.organization.security_account_id
}