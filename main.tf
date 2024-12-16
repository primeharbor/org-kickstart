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
      source  = "hashicorp/aws"
      version = ">= 5.80.0"
    }
  }
}

# Payer ID
data "external" "get_caller_identity" {
  program = ["aws", "sts", "get-caller-identity"]
}
data "aws_regions" "current" {}

#
# Security Service flags
variable "security_services" {
  description = "explictly disable or not manage a security service"
  default = {
    disable_guardduty   = "false"
    disable_macie       = "false"
    disable_inspector   = "false"
    disable_securityhub = "false"
  }
}

locals {
  payer_account_id = data.external.get_caller_identity.result.Account
  regions          = data.aws_regions.current.names
  default_tags     = var.tag_set
  security_services = merge(
    tomap({
      disable_guardduty   = "false"
      disable_macie       = "false"
      disable_inspector   = "false"
      disable_securityhub = "false"
    }),
    var.security_services
  )
}

#
# Create Default Provider for Management Account
#
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = local.default_tags
  }

}

provider "aws" {
  alias  = "security-account"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}