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

#
# Bucket
#
resource "aws_s3_bucket" "declarative_policy_bucket" {
  count    = var.declarative_policy_bucket_name == null ? 0 : 1
  bucket   = var.declarative_policy_bucket_name
}

resource "aws_s3_bucket_versioning" "declarative_policy_bucket" {
  count    = var.declarative_policy_bucket_name == null ? 0 : 1
  bucket   = aws_s3_bucket.declarative_policy_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "declarative_policy_bucket" {
  count    = var.declarative_policy_bucket_name == null ? 0 : 1
  bucket   = aws_s3_bucket.declarative_policy_bucket[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "declarative_policy_bucket_bpa" {
  count    = var.declarative_policy_bucket_name == null ? 0 : 1
  bucket   = aws_s3_bucket.declarative_policy_bucket[0].id

  # Modifying these settings prevents Terraform from running.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "declarative_policy_bucket_policy" {
  count    = var.declarative_policy_bucket_name == null ? 0 : 1
  bucket   = aws_s3_bucket.declarative_policy_bucket[0].id
  policy   = data.aws_iam_policy_document.declarative_policy_bucket_policy[0].json
}

data "aws_iam_policy_document" "declarative_policy_bucket_policy" {
  count = var.declarative_policy_bucket_name == null ? 0 : 1

  statement {
    sid    = "DeclarativePoliciesReportBucket"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["report.declarative-policies-ec2.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.declarative_policy_bucket[0].arn}/*"]
    condition {
      test = "StringLike"
      variable = "aws:SourceArn"
      values = ["arn:aws:declarative-policies-ec2:*:${aws_organizations_account.payer.id}:*"]
    }
  }
}

#
# Declarative Policies
#
module "declarative_policies" {
  for_each           = var.declarative_policies
  source             = "./modules/declarative_policies"
  policy_type        = "DECLARATIVE_POLICY_EC2"
  policy_name        = each.value["policy_name"]
  policy_description = each.value["policy_description"]
  policy_json        = templatefile(fileexists(each.value["policy_json_file"]) ? each.value["policy_json_file"] : "${path.module}/${each.value["policy_json_file"]}", lookup(each.value, "policy_vars", {}))
  policy_targets     = lookup(each.value, "policy_targets", ["Root"])
  ou_name_to_id      = local.ou_name_to_id # Pass the map to avoid regenerating it
  root_ou            = aws_organizations_organization.org.roots[0].id
}

output "declarative_policy_bucket" {
    value = aws_s3_bucket.declarative_policy_bucket[0].id

}