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

# The per-region security-services module (GuardDuty + Macie) was removed. Forget
# anything it created rather than destroying it, so the upgrade doesn't silently
# disable GuardDuty or Macie across the org. Use the wipe_*.py scripts to tear them
# down, or security_hub_configuration.enable_threat_detection to manage GuardDuty.
removed {
  from = module.security-services

  lifecycle {
    destroy = false
  }
}
