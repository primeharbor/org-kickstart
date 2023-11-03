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

#
# AWS SSO Instance Data
#
# This allows terraform to reference attributes of the AWS SSO Identity Storey
#
data "aws_ssoadmin_instances" "identity_store" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.identity_store.identity_store_ids)[0]
  instance_arn      = tolist(data.aws_ssoadmin_instances.identity_store.arns)[0]
}

resource "aws_ssoadmin_account_assignment" "account_group_assignment" {
  count            = var.disable_sso_management == true ? 0 : 1
  instance_arn       = local.instance_arn
  permission_set_arn = var.admin_permission_set_arn
  principal_id       = var.admin_group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.account.id
  target_type        = "AWS_ACCOUNT"
}

