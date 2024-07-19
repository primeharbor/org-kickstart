# Copyright 2024 Chris Farris <chris@primeharbor.com>
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


resource "aws_s3_bucket" "vpc_flowlogs_bucket" {
  count    = var.vpc_flowlogs_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = var.vpc_flowlogs_bucket_name
}

resource "aws_s3_bucket_versioning" "vpc_flowlogs_bucket" {
  count    = var.vpc_flowlogs_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.vpc_flowlogs_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "vpc_flowlogs_bucket" {
  count    = var.vpc_flowlogs_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.vpc_flowlogs_bucket[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flowlogs_bucket_bpa" {
  count    = var.vpc_flowlogs_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.vpc_flowlogs_bucket[0].id

  # Modifying these settings prevents Terraform from running.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "vpc_flowlogs_bucket_policy" {
  count    = var.vpc_flowlogs_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.vpc_flowlogs_bucket[0].id
  policy   = data.aws_iam_policy_document.vpc_flowlogs_bucket_policy[0].json
}

data "aws_iam_policy_document" "vpc_flowlogs_bucket_policy" {
  count = var.vpc_flowlogs_bucket_name == null ? 0 : 1

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.vpc_flowlogs_bucket[0].arn]
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.vpc_flowlogs_bucket[0].arn}/*"]
  }
}
