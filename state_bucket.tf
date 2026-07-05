# Copyright 2026 Chris Farris <chris@primeharbor.com>
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
# Optionally bring the Terraform state bucket (var.backend_bucket) under management.
#
# The bucket has to exist before Terraform can run (the S3 backend lives in it), so it is *adopted*
# rather than created. The `import` block that adopts it MUST live in the root/calling module --
# Terraform silently ignores import blocks declared inside a child module, and org-kickstart is
# almost always consumed as a module. See examples/pipeline/import.tf for the import block; copy it
# into your own root module when you enable manage_state_bucket.
#
# Set manage_state_bucket = false to leave the bucket entirely outside Terraform.

locals {
  # 1-element set (keyed by bucket name) when managing, empty set when not.
  state_bucket = var.manage_state_bucket ? toset([var.backend_bucket]) : toset([])
}

resource "aws_s3_bucket" "state_bucket" {
  for_each = local.state_bucket
  bucket   = each.value

  # The state bucket is the most important bucket in the org -- never let Terraform destroy it.
  # To stop managing it, remove it from state (terraform state rm) rather than toggling
  # manage_state_bucket, which would otherwise plan a destroy.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state_bucket" {
  for_each = local.state_bucket
  bucket   = aws_s3_bucket.state_bucket[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state_bucket" {
  for_each                = local.state_bucket
  bucket                  = aws_s3_bucket.state_bucket[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket" {
  for_each = local.state_bucket
  bucket   = aws_s3_bucket.state_bucket[each.key].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  # AWS injects extra rule attributes (blocked_encryption_types, bucket_key_enabled) after apply;
  # ignore them to prevent perpetual drift.
  lifecycle {
    ignore_changes = [rule]
  }
}
