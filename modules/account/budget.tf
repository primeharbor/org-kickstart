# Copyright 2025 Chris Farris <chris@primeharbor.com>
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


variable "warning_threshold_percentage" {
  description = "An Alert is sent when the actual costs this this percentage threshold"
  default     = 85
  type        = number
}

variable "monthly_budget_amount" {
  description = "Amount in default_currency that is set for this account"
  default     = 0
  type        = number
}

variable "default_currency" {
  description = "AWS Budgets Currency to measure in."
  default     = "USD"
}

variable "budget_alert_recipients" {
  description = "List of email addresses to get Buget Alerts"
  default     = []
  type        = list(string)
}

resource "aws_budgets_budget" "account" {
  count        = var.monthly_budget_amount == 0 ? 0 : 1
  name         = "${var.account_name} default monthly budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_amount
  limit_unit   = var.default_currency
  time_unit    = "MONTHLY"
  #   account_id   = aws_organizations_account.account.id

  cost_filter {
    name   = "LinkedAccount"
    values = [aws_organizations_account.account.id]
  }

  # We want three notifications. First when the forecast exceeds the limit
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_recipients
  }

  # Second when the Actual Cost his the warning threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.warning_threshold_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_recipients
  }

  # Finally when he budget is exceeded
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_recipients
  }

  # Highly Opinionated - I want to report budget only on usage, before credits and discounts, and
  # avoiding one-time charges.
  cost_types {
    include_credit             = false
    include_discount           = false # This is debatable for enterprise customers.
    include_other_subscription = false
    include_recurring          = false
    include_refund             = false
    include_subscription       = false
    include_support            = false
    include_tax                = true # This is part of the overall usage cost.
    include_upfront            = false
    use_blended                = false
  }

}