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

provider "aws" {
  alias  = "security-account-ap-south-1"
  region = "ap-south-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-eu-north-1"
  region = "eu-north-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-eu-west-3"
  region = "eu-west-3"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-ap-northeast-3"
  region = "ap-northeast-3"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-ap-northeast-2"
  region = "ap-northeast-2"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-ap-northeast-1"
  region = "ap-northeast-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-ca-central-1"
  region = "ca-central-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-sa-east-1"
  region = "sa-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-ap-southeast-1"
  region = "ap-southeast-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-ap-southeast-2"
  region = "ap-southeast-2"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-eu-central-1"
  region = "eu-central-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-us-east-1"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-us-east-2"
  region = "us-east-2"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-us-west-1"
  region = "us-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "security-account-us-west-2"
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}

