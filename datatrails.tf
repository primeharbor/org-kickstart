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


module "datatrail" {
  count  = var.datatrail == null ? 0 : 1
  source = "./modules/datatrail"
  providers = {
    aws.security-account = aws.security-account
  }
  bucket_name      = var.datatrail["bucket_name"]
  trail_name       = var.datatrail["trail_name"]
  excluded_buckets = var.datatrail["excluded_buckets"]
  enabled          = var.datatrail["enabled"]
}