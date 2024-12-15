#!/bin/bash

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

# Disable the Root Credentials in an AWS Account.
# Base on script from https://gist.github.com/sebsto/6f7c9eaf500ac11756a86babde75ffc0

AWS_ACCOUNT_ID=$1

if [ -z "$AWS_ACCOUNT_ID" ] ; then
  echo "USAGE: $0 <AWS_ACCOUNT_ID>"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq to parse JSON."
    exit 1
fi

# ask for temporary credentials for the target account
aws sts assume-root --target-principal ${AWS_ACCOUNT_ID} \
                    --task-policy-arn arn=arn:aws:iam::aws:policy/root-task/IAMDeleteRootUserCredentials > $AWS_ACCOUNT_ID-credentials.json

# Check if credentials.json file exists
if [ ! -f "$AWS_ACCOUNT_ID-credentials.json" ]; then
    echo "Error: $AWS_ACCOUNT_ID-credentials.json file not found."
    exit 1
fi

# Extract credentials from JSON and set environment variables
export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' $AWS_ACCOUNT_ID-credentials.json)
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' $AWS_ACCOUNT_ID-credentials.json)
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' $AWS_ACCOUNT_ID-credentials.json)

# do not leave the credentials file behind
rm $AWS_ACCOUNT_ID-credentials.json

# Verify if the variables are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
    echo "Error: Failed to extract one or more credentials from the JSON."
    exit 1
fi

# Print success message
echo "AWS credentials have been successfully set as environment variables."
echo "You can now use these credentials in your AWS CLI or SDK applications."

# Run an action as root on the member account
echo -n "Got Credentials for "
aws sts get-caller-identity --query Arn --output text

aws iam delete-login-profile
exit $?