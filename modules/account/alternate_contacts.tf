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

resource "aws_account_alternate_contact" "operations" {
  count                  = var.operations_contact != null ? 1 : 0
  alternate_contact_type = "OPERATIONS"
  account_id             = aws_organizations_account.account.id
  name                   = var.operations_contact["name"]
  title                  = var.operations_contact["title"]
  email_address          = var.operations_contact["email_address"]
  phone_number           = var.operations_contact["phone_number"]
}

resource "aws_account_primary_contact" "primary" {
  count              = var.primary_contact != null ? 1 : 0
  account_id         = aws_organizations_account.account.id
  full_name          = var.primary_contact["full_name"]
  company_name       = lookup(var.primary_contact, "company_name", null)
  address_line_1     = var.primary_contact["address_line_1"]
  address_line_2     = lookup(var.primary_contact, "address_line_2", null)
  address_line_3     = lookup(var.primary_contact, "address_line_3", null)
  city               = var.primary_contact["city"]
  district_or_county = lookup(var.primary_contact, "district_or_county", null)
  state_or_region    = lookup(var.primary_contact, "state_or_region", null)
  postal_code        = var.primary_contact["postal_code"]
  country_code       = var.primary_contact["country_code"]
  phone_number       = var.primary_contact["phone_number"]
  website_url        = lookup(var.primary_contact, "website_url", null)
}