# Copyright 2024 Chris Farris <chris@primeharbor.com>
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

resource "aws_cloudformation_stack" "account_factory" {
  count        = var.account_configurator == null ? 0 : 1
  name         = "org-kickstart-account-configurator"
  template_url = var.account_configurator["template"]
  on_failure   = "DELETE"

  parameters = {
    pBucketName = var.backend_bucket
    pConfigFile = var.account_configurator["account_factory_config_file"]
  }

  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_NAMED_IAM",
    "CAPABILITY_AUTO_EXPAND"
  ]

}

resource "aws_s3_object" "account_factory_config" {
  count  = var.account_configurator == null ? 0 : 1
  bucket = var.backend_bucket
  key    = var.account_configurator["account_factory_config_file"]
  source = "${path.root}/${var.account_configurator["account_factory_config_file"]}"
}

