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

resource "aws_account_alternate_contact" "billing" {
  count                  = var.billing_contact != null ? 1 : 0
  alternate_contact_type = "BILLING"
  account_id             = aws_organizations_account.account.id
  name                   = var.billing_contact["name"]
  title                  = var.billing_contact["title"]
  email_address          = var.billing_contact["email_address"]
  phone_number           = var.billing_contact["phone_number"]
}

resource "aws_account_alternate_contact" "security" {
  count                  = var.security_contact != null ? 1 : 0
  alternate_contact_type = "SECURITY"
  account_id             = aws_organizations_account.account.id
  name                   = var.security_contact["name"]
  title                  = var.security_contact["title"]
  email_address          = var.security_contact["email_address"]
  phone_number           = var.security_contact["phone_number"]
}