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
  alias  = "payer-ap-south-1"
  region = "ap-south-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-eu-north-1"
  region = "eu-north-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-eu-west-3"
  region = "eu-west-3"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-eu-west-2"
  region = "eu-west-2"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-eu-west-1"
  region = "eu-west-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-ap-northeast-3"
  region = "ap-northeast-3"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-ap-northeast-2"
  region = "ap-northeast-2"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-ap-northeast-1"
  region = "ap-northeast-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-ca-central-1"
  region = "ca-central-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-sa-east-1"
  region = "sa-east-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-ap-southeast-1"
  region = "ap-southeast-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-ap-southeast-2"
  region = "ap-southeast-2"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-eu-central-1"
  region = "eu-central-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-us-east-1"
  region = "us-east-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-us-east-2"
  region = "us-east-2"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-us-west-1"
  region = "us-west-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "payer-us-west-2"
  region = "us-west-2"
  default_tags {
    tags = local.default_tags
  }
}

