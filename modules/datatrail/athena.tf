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

# Athena Workgroup
resource "aws_athena_workgroup" "datatrail" {
  provider = aws.security-account
  name     = "${var.trail_name}-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_output.bucket}/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.athena_kms_key.arn
      }
    }

    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = 1000000000 # 1GB cost control
    requester_pays_enabled             = false
  }
}

# Glue Database for Athena
resource "aws_glue_catalog_database" "datatrail" {
  provider = aws.security-account
  name     = "datatrail"
}


# S3 Bucket for Athena query results
resource "aws_s3_bucket" "athena_output" {
  provider      = aws.security-account
  bucket        = "${var.bucket_name}-athena-results"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "athena_output" {
  provider = aws.security-account
  bucket   = aws_s3_bucket.athena_output.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_output" {
  provider = aws.security-account
  bucket   = aws_s3_bucket.athena_output.id

  rule {
    blocked_encryption_types = ["SSE-C"]
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.athena_kms_key.arn
    }
  }
}

# KMS Key for Athena query results encryption
resource "aws_kms_key" "athena_kms_key" {
  provider                = aws.security-account
  description             = "KMS key for Athena datatrail workgroup"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "athena_kms_key_alias" {
  provider      = aws.security-account
  name          = "alias/athena-datatrail"
  target_key_id = aws_kms_key.athena_kms_key.key_id
}




