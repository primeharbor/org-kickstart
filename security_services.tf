# Copyright 2026 Chris Farris <chris@primeharbor.com>
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

# Data source to dynamically fetch all available AWS regions
data "aws_regions" "available" {
  all_regions = false # Only include regions that are enabled in your account
}

locals {
  # Uses the aws_regions data source to automatically discover all enabled regions
  aws_regions = data.aws_regions.available.names
}

module "security-services" {
  for_each = toset(local.aws_regions)
  region   = each.value
  source   = "./modules/security_services"
  providers = {
    aws.security_account = aws.security-account
    aws.payer_account    = aws
  }
  security_account_id = module.security_account.account_id
  security_services   = var.security_services
  # macie_key_arn       = module.organization.macie_key_arn
  # macie_bucket_name   = var.organization["macie_bucket_name"]
}
