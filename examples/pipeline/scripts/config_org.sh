#!/bin/bash
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

TF_DATA=$1
SSO_NAME=$2

if [ -z "$SSO_NAME" ] ; then
  echo "USAGE: $0 output-ENV.json <SSO_NAME>"
  exit 1
fi

SSO_INSTANCE_ARN=`jq -r .sso_instance_arn.value $TF_DATA`
aws sso-admin update-instance --name $SSO_NAME --instance-arn $SSO_INSTANCE_ARN

