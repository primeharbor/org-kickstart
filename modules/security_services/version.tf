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

# Module: security_services
# Version: 1.0.0
#
# Purpose: Enables regional security services across the organization
#
# Managed Services:
# - AWS GuardDuty
# - Amazon Macie
# - AWS Security Hub
# - Amazon Inspector v2
#
# Features:
# - Multi-region deployment
# - Automatic member account association
# - Security account as delegated administrator
# - Per-service enable/disable flags
