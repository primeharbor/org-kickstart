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

# Module: org_policies
# Version: 1.0.0
#
# Purpose: Generic module for managing AWS Organizations policies
#
# Supported Policy Types:
# - SERVICE_CONTROL_POLICY
# - RESOURCE_CONTROL_POLICY
# - DECLARATIVE_POLICY_EC2
#
# Features:
# - Policy creation with templating support
# - Flexible targeting (OU names, OU IDs, or root)
# - Optional attachment control via do_not_attach flag
