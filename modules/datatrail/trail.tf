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

resource "aws_cloudtrail" "datatrail" {
  depends_on     = [aws_s3_bucket_policy.datatrail_bucket]
  name           = var.trail_name
  s3_bucket_name = aws_s3_bucket.datatrail_bucket.id
  # s3_key_prefix                 = "prefix"
  include_global_service_events = true
  enable_log_file_validation    = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_logging                = var.enabled

  advanced_event_selector {
    name = "Log Data Events for all Buckets except the ones excluded"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field = "resources.ARN"
      # Exclude the passed in list, and always exclude the data trail bucket itself to prevent recursion
      not_starts_with = [for bucket in concat(var.excluded_buckets, [var.bucket_name]) : "arn:${data.aws_partition.payer.partition}:s3:::${bucket}/"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
  }
}

#
# Data Trail Bucket
#
resource "aws_s3_bucket" "datatrail_bucket" {
  provider      = aws.security-account
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "datatrail_bucket" {
  provider = aws.security-account
  bucket   = aws_s3_bucket.datatrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "datatrail_bucket" {
  provider = aws.security-account
  bucket   = aws_s3_bucket.datatrail_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "datatrail_bucket" {
  provider                = aws.security-account
  bucket                  = aws_s3_bucket.datatrail_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "datatrail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.datatrail_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.payer.partition}:cloudtrail:${data.aws_region.payer.region}:${data.aws_caller_identity.payer.account_id}:trail/${var.trail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.datatrail_bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.payer.partition}:cloudtrail:${data.aws_region.payer.region}:${data.aws_caller_identity.payer.account_id}:trail/${var.trail_name}"]
    }
  }
}

resource "aws_s3_bucket_policy" "datatrail_bucket" {
  provider = aws.security-account
  bucket   = aws_s3_bucket.datatrail_bucket.id
  policy   = data.aws_iam_policy_document.datatrail_bucket.json
}

