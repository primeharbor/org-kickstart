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

resource "aws_securityhub_account" "payer_account" {
  count = local.security_services["disable_securityhub"] ? 0 : 1
  enable_default_standards  = false
  control_finding_generator = "SECURITY_CONTROL"
  auto_enable_controls      = false
}

# We need to create the hub in the security account _before_ we delegate admin
# Otherwise, AWS will create the hub with incorrect defaults
resource "aws_securityhub_account" "security_account" {
  count                     = local.security_services["disable_securityhub"] ? 0 : 1
  provider                  = aws.security-account
  enable_default_standards  = false
  control_finding_generator = "SECURITY_CONTROL"
  auto_enable_controls      = false
}

resource "aws_organizations_delegated_administrator" "securityhub" {
  count             = local.security_services["disable_securityhub"] ? 0 : 1
  account_id        = module.security_account.account_id
  service_principal = "securityhub.amazonaws.com"
  depends_on = [
    aws_securityhub_account.payer_account[0],
    aws_securityhub_account.security_account[0]
  ]
}

# Once both hubs are created, we can delegate admin to the security account
resource "aws_securityhub_organization_admin_account" "delegated_admin" {
  count = local.security_services["disable_securityhub"] ? 0 : 1
  depends_on = [
    aws_securityhub_account.payer_account[0],
    aws_securityhub_account.security_account[0]
  ]
  admin_account_id = module.security_account.account_id
}

resource "aws_securityhub_finding_aggregator" "regional_aggregator" {
  depends_on = [
    aws_securityhub_account.security_account[0],
    aws_securityhub_organization_admin_account.delegated_admin[0]
  ]
  count        = local.security_services["disable_securityhub"] ? 0 : 1
  provider     = aws.security-account
  linking_mode = "ALL_REGIONS"
}

# Once the delegation is complete, we create the organization config.
resource "aws_securityhub_organization_configuration" "security_account" {
  depends_on = [
    aws_securityhub_account.security_account[0],
    aws_securityhub_finding_aggregator.regional_aggregator[0],
    aws_securityhub_organization_admin_account.delegated_admin[0]
  ]
  count                 = local.security_services["disable_securityhub"] ? 0 : 1
  provider              = aws.security-account
  auto_enable           = false
  auto_enable_standards = "NONE"

  organization_configuration {
    configuration_type = "CENTRAL"
  }
}

resource "aws_securityhub_configuration_policy" "no_enabled_standards" {
  count       = local.security_services["disable_securityhub"] ? 0 : 1
  provider    = aws.security-account
  depends_on  = [aws_securityhub_organization_configuration.security_account[0]]
  name        = "NoStandards"
  description = "Enable Security Hub Central Configuration without any Standards"

  configuration_policy {
    service_enabled = true
    enabled_standard_arns = [
      #   "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0",
      #   "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
    ]
    security_controls_configuration {
      disabled_control_identifiers = []
    }
  }
}

resource "aws_securityhub_configuration_policy_association" "root_ou" {
  count     = local.security_services["disable_securityhub"] ? 0 : 1
  provider  = aws.security-account
  target_id = aws_organizations_organization.org.roots[0].id
  policy_id = aws_securityhub_configuration_policy.no_enabled_standards[0].id
}