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
# Declarative imports for the foundational resources of an org-kickstart deployment.
#
# Three things must exist before Terraform can manage them, and cannot be created by this module:
#   * the AWS Organization      (you enable Organizations in the console first)
#   * the payer/management account (it is the account you are running Terraform in)
#   * the Terraform state bucket (the S3 backend lives in it; create with `aws s3 mb`)
#
# Adopting them here with import blocks means a brand-new org does NOT need to run
# scripts/import_org.sh -- that script is now only required when adopting an *existing* org that
# already has accounts, OUs, or policies to import.
#
# These import blocks must live in the root module: Terraform silently ignores import blocks
# declared inside a child module, and org-kickstart is consumed as module.organization.
#
# All three imports are idempotent -- once the resources are in state, they are no-ops.

data "aws_organizations_organization" "current" {}

# The AWS Organization itself.
import {
  to = module.organization.aws_organizations_organization.org
  id = data.aws_organizations_organization.current.id
}

# The payer / management account (the account Terraform is running in).
import {
  to = module.organization.aws_organizations_account.payer
  id = data.aws_organizations_organization.current.master_account_id
}

# The Terraform state bucket, only when managed (manage_state_bucket = true).
import {
  for_each = lookup(var.organization, "manage_state_bucket", true) ? toset([var.backend_bucket]) : toset([])
  to       = module.organization.aws_s3_bucket.state_bucket[each.key]
  id       = each.value
}
