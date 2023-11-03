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


# SSO Should have been enabled prior to deploying the kickstart. In fact, it cannot be created via API, only console.
data "aws_ssoadmin_instances" "identity_store" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.identity_store.identity_store_ids)[0]
  instance_arn      = tolist(data.aws_ssoadmin_instances.identity_store.arns)[0]
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_policy_attachments" {
  depends_on         = [aws_ssoadmin_permission_set.admin_permission_set]
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_permission_set.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_permission_set" "admin_permission_set" {
  name         = var.admin_permission_set_name
  description  = "Grant Full Admin Permissions"
  instance_arn = local.instance_arn
  # relay_state      = "https://s3.console.aws.amazon.com/s3/home?region=us-east-1#"
  session_duration = var.session_duration
}

resource "aws_identitystore_group" "admin_group" {
  display_name      = "AllAdmins"
  description       = "Default Group for all Cloud Admins"
  identity_store_id = local.identity_store_id
}

