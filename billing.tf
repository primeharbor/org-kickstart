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

# Suggestion from Mark Wolfe
#  "I would also setup billing/CUR exports to s3, ideally from the root account to an s3 bucket in a logging or audit account."


#
# The Bucket config is taken from
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/billing_service_account
#
data "aws_billing_service_account" "main" {}

resource "aws_s3_bucket" "billing_logs" {
  count  = var.billing_data_bucket_name != null ? 1 : 0
  bucket = var.billing_data_bucket_name
}

resource "aws_s3_bucket_public_access_block" "billing_logs" {
  count  = var.billing_data_bucket_name != null ? 1 : 0
  bucket = aws_s3_bucket.billing_logs[0].id

  # Modifying these settings prevents Terraform from running.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "allow_billing_logging" {
  count = var.billing_data_bucket_name != null ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_billing_service_account.main.arn]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
    ]
    resources = [aws_s3_bucket.billing_logs[0].arn]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_billing_service_account.main.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.billing_logs[0].arn}/*"]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.billing_logs[0].arn,
      "${aws_s3_bucket.billing_logs[0].arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [aws_organizations_account.payer.id]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cur:${data.aws_region.current.name}:${aws_organizations_account.payer.id}:definition/*"]
    }

  }

}

resource "aws_s3_bucket_policy" "allow_billing_logging" {
  count  = var.billing_data_bucket_name != null ? 1 : 0
  bucket = aws_s3_bucket.billing_logs[0].id
  policy = data.aws_iam_policy_document.allow_billing_logging[0].json
}


#
# These recommendations are from Mike Julian @ the Duckbill Group
#
resource "aws_cur_report_definition" "cur_report_definition" {
  count                      = var.cur_report_frequency != "NONE" ? 1 : 0
  report_name                = "athena-cur-report"
  time_unit                  = var.cur_report_frequency
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]
  s3_bucket                  = aws_s3_bucket.billing_logs[0].id
  s3_prefix                  = "athena-cur-report"
  s3_region                  = data.aws_region.current.name
  additional_artifacts       = ["ATHENA"]
  report_versioning          = "OVERWRITE_REPORT"
}

resource "aws_budgets_budget" "organization" {
  count        = lookup(var.budget_defaults, "organizational_budget", 0) == 0 ? 0 : 1
  name         = "${var.organization_name} Organization Default Monthly Budget"
  budget_type  = "COST"
  limit_amount = lookup(var.budget_defaults, "organizational_budget")
  limit_unit   = lookup(var.budget_defaults, "currency", "USD")
  time_unit    = "MONTHLY"
  account_id   = aws_organizations_account.payer.id


  # We want three notifications. First when the forecast exceeds the limit
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = lookup(var.budget_defaults, "alert_recipients", [])
  }

  # Second when the Actual Cost his the warning threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = lookup(var.budget_defaults, "warning_percentage", 85)
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = lookup(var.budget_defaults, "alert_recipients", [])
  }

  # Finally when he budget is exceeded
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = lookup(var.budget_defaults, "alert_recipients", [])
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