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


PAYER_PROFILE=$1
SECURITY_PROFILE=$2

OUTFILE=import_guardduty.tf

if [[ -z $SECURITY_PROFILE ]] ; then
  echo "Usage: $0 <PAYER_PROFILE> <SECURITY_PROFILE>"
  exit 1
fi

SECURITY_ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text --profile $SECURITY_PROFILE`
PAYER_ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text --profile $PAYER_PROFILE`

ACCOUNT_LIST=`aws organizations list-accounts --query Accounts[].Id --output text --profile $PAYER_PROFILE`

REGIONS=`aws ec2 describe-regions  | jq -r '.Regions[].RegionName'`
for REGION in $REGIONS ; do 
    PAYER_DETECTOR=`aws guardduty list-detectors --query DetectorIds[0] --output text --region $REGION --profile $PAYER_PROFILE`
    SECURITY_DETECTOR=`aws guardduty list-detectors --query DetectorIds[0] --output text --region $REGION --profile $SECURITY_PROFILE`
    cat <<EOF > $OUTFILE
import {
  to = module.security-services-$REGION.aws_guardduty_detector.payer_detector[0]
  id = "$PAYER_DETECTOR"
}
import {
  to = module.security-services-$REGION.aws_guardduty_detector.security_detector[0]
  id = "$SECURITY_DETECTOR"
}
import {
  to = module.security-services-$REGION.aws_guardduty_organization_configuration.organization[0]
  id = "$SECURITY_DETECTOR"
}
import {
  to = module.security-services-$REGION.aws_guardduty_organization_admin_account.guardduty[0]
  id = "$SECURITY_ACCOUNT_ID"
}
EOF

    for a in $ACCOUNT_LIST ; do 
      if [[ $a == $SECURITY_ACCOUNT_ID ]] ; then
        continue  # Cannot add the security account as a member of itself
      fi

    cat <<EOF >> $OUTFILE
import { 
    to = module.security-services-$REGION.aws_guardduty_member.member["$a"]
    id = "$SECURITY_DETECTOR:$a"
}
EOF
    done

done