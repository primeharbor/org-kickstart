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

# This has to be done 17 times for each region because terraform providers are stupid

module "security-services-ap-south-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-ap-south-1
    aws.payer_account    = aws.payer-ap-south-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-eu-north-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-eu-north-1
    aws.payer_account    = aws.payer-eu-north-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-eu-west-3" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-eu-west-3
    aws.payer_account    = aws.payer-eu-west-3
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-eu-west-2" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-eu-west-2
    aws.payer_account    = aws.payer-eu-west-2
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-eu-west-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-eu-west-1
    aws.payer_account    = aws.payer-eu-west-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-ap-northeast-3" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-ap-northeast-3
    aws.payer_account    = aws.payer-ap-northeast-3
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-ap-northeast-2" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-ap-northeast-2
    aws.payer_account    = aws.payer-ap-northeast-2
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-ap-northeast-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-ap-northeast-1
    aws.payer_account    = aws.payer-ap-northeast-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-ca-central-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-ca-central-1
    aws.payer_account    = aws.payer-ca-central-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-sa-east-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-sa-east-1
    aws.payer_account    = aws.payer-sa-east-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-ap-southeast-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-ap-southeast-1
    aws.payer_account    = aws.payer-ap-southeast-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-ap-southeast-2" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-ap-southeast-2
    aws.payer_account    = aws.payer-ap-southeast-2
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-eu-central-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-eu-central-1
    aws.payer_account    = aws.payer-eu-central-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-us-east-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-us-east-1
    aws.payer_account    = aws.payer-us-east-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-us-east-2" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-us-east-2
    aws.payer_account    = aws.payer-us-east-2
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-us-west-1" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-us-west-1
    aws.payer_account    = aws.payer-us-west-1
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
module "security-services-us-west-2" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-us-west-2
    aws.payer_account    = aws.payer-us-west-2
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}
