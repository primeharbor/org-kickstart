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
      values   = ["arn:aws:cur:us-east-1:${aws_organizations_account.payer.id}:definition/*"]
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
  s3_region                  = "us-east-1"
  additional_artifacts       = ["ATHENA"]
  report_versioning          = "OVERWRITE_REPORT"
}