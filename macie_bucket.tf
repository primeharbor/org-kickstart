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
# Bucket
#
resource "aws_s3_bucket" "macie_bucket" {
  count    = var.macie_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = var.macie_bucket_name
}

resource "aws_s3_bucket_versioning" "macie_bucket" {
  count    = var.macie_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.macie_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "macie_bucket" {
  count    = var.macie_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.macie_bucket[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "macie_bucket_bpa" {
  count    = var.macie_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.macie_bucket[0].id

  # Modifying these settings prevents Terraform from running.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "macie_bucket_policy" {
  count    = var.macie_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.macie_bucket[0].id
  policy   = data.aws_iam_policy_document.macie_bucket_policy[0].json
}

data "aws_iam_policy_document" "macie_bucket_policy" {
  count = var.macie_bucket_name == null ? 0 : 1
  statement {
    sid    = "AclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["macie.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.macie_bucket[0].arn]
  }

  statement {
    sid    = "ServiceWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["macie.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.macie_bucket[0].arn}/*"]
  }
}

#
# KMS
#
resource "aws_kms_key" "macie_key" {
  count                   = var.macie_bucket_name == null ? 0 : 1
  provider                = aws.security-account
  description             = "This key is used for Macie Findings"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "macie_key" {
  count                   = var.macie_bucket_name == null ? 0 : 1
  provider                = aws.security-account
  name          = "alias/macie-findings"
  target_key_id = aws_kms_key.macie_key[0].key_id
}

resource "aws_kms_key_policy" "macie_key" {
  count    = var.macie_bucket_name == null ? 0 : 1
  provider = aws.security-account
  key_id   = aws_kms_key.macie_key[0].id
  policy = jsonencode({
    Id      = "macie"
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${module.security_account.account_id}:root"
        }
        Resource = "*"
      },
      {
        Sid = "Macie Permissions"
        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ]
        Effect = "Allow"
        Principal = {
          Service = "macie.amazonaws.com"
        }
        Resource = "*"
      }
    ]
  })
}


resource "aws_s3_bucket_server_side_encryption_configuration" "macie_bucket" {
  count    = var.macie_bucket_name == null ? 0 : 1
  provider = aws.security-account
  bucket   = aws_s3_bucket.macie_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.macie_key[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}
