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


resource "aws_s3_bucket" "billing_logs" {
  count  = var.billing_data_bucket_name != null ? 1 : 0
  bucket = var.billing_data_bucket_name
  region = "eusc-de-east-1"
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

resource "aws_s3_bucket_lifecycle_configuration" "billing_logs" {
  count  = var.billing_data_bucket_name != null ? 1 : 0
  bucket = aws_s3_bucket.billing_logs[0].id

  rule {
    id     = "archive-old-billing-reports"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

data "aws_iam_policy_document" "allow_billing_logging" {
  count = var.billing_data_bucket_name != null ? 1 : 0

  statement {
    sid    = "EnableDataExportsToWriteToS3"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.billing_logs[0].arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [aws_organizations_account.payer.id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:bcm-data-exports:${data.aws_region.current.region}:${aws_organizations_account.payer.id}:export/*"]
    }
  }

}

resource "aws_s3_bucket_policy" "allow_billing_logging" {
  count  = var.billing_data_bucket_name != null ? 1 : 0
  bucket = aws_s3_bucket.billing_logs[0].id
  policy = data.aws_iam_policy_document.allow_billing_logging[0].json
}


#
# CUR 2.0 via AWS Data Exports
# Recommendations from Mike Julian @ the Duckbill Group, updated for Data Exports API
#
resource "aws_bcmdataexports_export" "cur" {
  count = var.cur_report_frequency != "NONE" ? 1 : 0

  export {
    name = "athena-cur-report"

    data_query {
      query_statement = <<-EOT
        SELECT identity_line_item_id,
               identity_time_interval,
               bill_invoice_id,
               bill_invoicing_entity,
               bill_billing_entity,
               bill_bill_type,
               bill_payer_account_id,
               bill_payer_account_name,
               bill_billing_period_start_date,
               bill_billing_period_end_date,
               line_item_usage_account_id,
               line_item_usage_account_name,
               line_item_line_item_type,
               line_item_usage_start_date,
               line_item_usage_end_date,
               line_item_product_code,
               line_item_usage_type,
               line_item_operation,
               line_item_availability_zone,
               line_item_usage_amount,
               line_item_normalization_factor,
               line_item_normalized_usage_amount,
               line_item_currency_code,
               line_item_unblended_rate,
               line_item_unblended_cost,
               line_item_blended_rate,
               line_item_blended_cost,
               line_item_line_item_description,
               line_item_tax_type,
               line_item_net_unblended_rate,
               line_item_net_unblended_cost,
               line_item_legal_entity,
               product_servicecode,
               product_operation,
               product_usagetype,
               product_sku,
               product_product_family,
               product_comment,
               product_fee_code,
               product_fee_description,
               product_location,
               product_location_type,
               product_region_code,
               product_from_location,
               product_from_location_type,
               product_from_region_code,
               product_to_location,
               product_to_location_type,
               product_to_region_code,
               product_instance_family,
               product_instance_type,
               product_instancesku,
               product_pricing_unit,
               product,
               pricing_lease_contract_length,
               pricing_offering_class,
               pricing_purchase_option,
               pricing_rate_code,
               pricing_rate_id,
               pricing_currency,
               pricing_public_on_demand_rate,
               pricing_public_on_demand_cost,
               pricing_term,
               pricing_unit,
               reservation_availability_zone,
               reservation_start_time,
               reservation_end_time,
               reservation_modification_status,
               reservation_amortized_upfront_cost_for_usage,
               reservation_amortized_upfront_fee_for_billing_period,
               reservation_unused_amortized_upfront_fee_for_billing_period,
               reservation_recurring_fee_for_usage,
               reservation_unused_recurring_fee,
               reservation_effective_cost,
               reservation_upfront_value,
               reservation_net_amortized_upfront_cost_for_usage,
               reservation_net_amortized_upfront_fee_for_billing_period,
               reservation_net_unused_amortized_upfront_fee_for_billing_period,
               reservation_net_recurring_fee_for_usage,
               reservation_net_unused_recurring_fee,
               reservation_net_effective_cost,
               reservation_net_upfront_value,
               reservation_normalized_units_per_reservation,
               reservation_number_of_reservations,
               reservation_reservation_a_r_n,
               reservation_subscription_id,
               reservation_total_reserved_normalized_units,
               reservation_total_reserved_units,
               reservation_units_per_reservation,
               reservation_unused_normalized_unit_quantity,
               reservation_unused_quantity,
               savings_plan_total_commitment_to_date,
               savings_plan_savings_plan_a_r_n,
               savings_plan_savings_plan_rate,
               savings_plan_used_commitment,
               savings_plan_savings_plan_effective_cost,
               savings_plan_amortized_upfront_commitment_for_billing_period,
               savings_plan_recurring_commitment_for_billing_period,
               savings_plan_net_savings_plan_effective_cost,
               savings_plan_net_amortized_upfront_commitment_for_billing_period,
               savings_plan_net_recurring_commitment_for_billing_period,
               savings_plan_start_time,
               savings_plan_end_time,
               savings_plan_instance_type_family,
               savings_plan_offering_type,
               savings_plan_payment_option,
               savings_plan_purchase_term,
               savings_plan_region,
               discount_bundled_discount,
               discount_total_discount,
               discount,
               resource_tags,
               cost_category
        FROM COST_AND_USAGE_REPORT
      EOT
      table_configurations = {
        COST_AND_USAGE_REPORT = {
          TIME_GRANULARITY                      = var.cur_report_frequency
          INCLUDE_RESOURCES                     = "TRUE"
          INCLUDE_SPLIT_COST_ALLOCATION_DATA    = "FALSE"
          INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = "FALSE"
        }
      }
    }

    destination_configurations {
      s3_destination {
        s3_bucket = aws_s3_bucket.billing_logs[0].id
        s3_prefix = "athena-cur-report"
        s3_region = data.aws_region.current.region

        s3_output_configurations {
          format      = "PARQUET"
          compression = "PARQUET"
          output_type = "CUSTOM"
          overwrite   = "OVERWRITE_REPORT"
        }
      }
    }

    refresh_cadence {
      frequency = "SYNCHRONOUS"
    }
  }

  # EUSC: the API always returns BILLING_VIEW_ARN="" in the response even when
  # not set, but sending it explicitly in the request causes AccessDeniedException.
  # Ignoring table_configurations after creation prevents spurious replace cycles.
  lifecycle {
    ignore_changes = [export[0].data_query[0].table_configurations]
  }
}

resource "aws_budgets_budget" "organization" {
  count        = var.budget_defaults.organizational_budget != 0 ? 1 : 0
  name         = "${var.organization_name} Organization Default Monthly Budget"
  budget_type  = "COST"
  limit_amount = var.budget_defaults.organizational_budget
  limit_unit   = var.budget_defaults.currency
  time_unit    = "MONTHLY"
  account_id   = aws_organizations_account.payer.id


  # We want three notifications. First when the forecast exceeds the limit
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_defaults.alert_recipients
  }

  # Second when the Actual Cost his the warning threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_defaults.warning_percentage
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_defaults.alert_recipients
  }

  # Finally when he budget is exceeded
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_defaults.alert_recipients
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
