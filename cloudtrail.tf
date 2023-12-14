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
# The Bucket is created in the security account
#
resource "aws_s3_bucket" "cloudtrail_bucket" {
  count    = var.cloudtrail_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = var.cloudtrail_bucket_name
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket" {
  count    = var.cloudtrail_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.cloudtrail_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_bucket" {
  count    = var.cloudtrail_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.cloudtrail_bucket[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_bpa" {
  count    = var.cloudtrail_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.cloudtrail_bucket[0].id

  # Modifying these settings prevents Terraform from running.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  count    = var.cloudtrail_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.cloudtrail_bucket[0].id
  policy   = data.aws_iam_policy_document.cloudtrail_bucket_policy[0].json
}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  count = var.cloudtrail_bucket_name == null ? 0 : 1
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_bucket[0].arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_bucket[0].arn}/*"]
  }

  statement {
    sid    = "IAMAccessAnalyzer"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.cloudtrail_bucket[0].arn,
      "${aws_s3_bucket.cloudtrail_bucket[0].arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [aws_organizations_organization.org.id]
    }
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::&{aws:PrincipalAccount}:role/service-role/AccessAnalyzerMonitorServiceRole*"]
    }
  }
}

#
# S3 Object Notification to SNS
#
data "aws_iam_policy_document" "cloudtrail_s3_notification_topic" {
  count = var.cloudtrail_bucket_name == null ? 0 : 1
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:cloudtrail-s3-event-notification-topic"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.cloudtrail_bucket[0].arn]
    }
  }
}

resource "aws_sns_topic" "cloudtrail_s3_notification_topic" {
  count    = var.cloudtrail_bucket_name == null ? 0 : 1
  provider = aws.security-account
  name     = "cloudtrail-s3-event-notification-topic"
  policy   = data.aws_iam_policy_document.cloudtrail_s3_notification_topic[0].json
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count    = var.cloudtrail_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.cloudtrail_bucket[0].id

  topic {
    topic_arn     = aws_sns_topic.cloudtrail_s3_notification_topic[0].arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".json.gz"
    filter_prefix = "AWSLogs/"
  }
}

#
# And the Trail is created in the Management Account
#
resource "aws_cloudtrail" "org_cloudtrail" {
  count                         = var.cloudtrail_bucket_name != null ? 1 : 0
  depends_on                    = [aws_s3_bucket.cloudtrail_bucket[0]]
  name                          = "org_cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket[0].id
  include_global_service_events = true
  enable_log_file_validation    = true
  is_multi_region_trail         = true
  is_organization_trail         = true
}

output "cloudtrail_s3_notification_topic" {
  value = var.cloudtrail_bucket_name != null ? aws_sns_topic.cloudtrail_s3_notification_topic[0].arn : null
}