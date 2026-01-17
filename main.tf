/**
 * # Org-Kickstart
 *
 * Copyright 2023 Chris Farris <chris@primeharbor.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */



terraform {
  required_version = ">= 1.0, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.22.0"
    }
  }
}

locals {
  default_tags = var.tag_set
}

#
# Create Default Provider for Management Account
#
provider "aws" {
  default_tags {
    tags = local.default_tags
  }

}

provider "aws" {
  alias = "security-account"
  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

data "aws_region" "current" {}

data "aws_partition" "current" {}
