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


module "billing_alerts" {
  source = "./modules/billing_alerts"
  count  = var.billing_alerts == null ? 0 : 1

  payer_email           = var.payer_email
  organization_name     = var.organization_name
  billing_levels        = lookup(var.billing_alerts, "levels", {})
  billing_subscriptions = lookup(var.billing_alerts, "subscriptions", [])

}
