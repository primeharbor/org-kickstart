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


ORG_ID=`aws organizations describe-organization --query Organization.Id --output text`
PAYER_ID=`aws sts get-caller-identity --query Account --output text`
SECURITY_ACCOUNT_ID=`aws organizations list-accounts --query Accounts[].[Name,Id] --output text | grep security | awk '{print $NF}'`

OUTFILE=import-org.tf

cat <<EOF > $OUTFILE
import {
  to = module.organization.aws_organizations_organization.org
  id = "$ORG_ID"
}
import {
  to = module.organization.aws_organizations_account.payer
  id = "$PAYER_ID"
}
EOF

if [[ ! -z $SECURITY_ACCOUNT_ID ]] ; then
cat <<EOF >> $OUTFILE
import {
  to =  module.organization.module.security_account.aws_organizations_account.account
  id = "$SECURITY_ACCOUNT_ID"
}

EOF
fi



aws organizations list-accounts > accounts.json

ACCOUNT_IDS=`cat accounts.json | jq -r .Accounts[].Id`
ACCOUNT_COUNT=`echo $ACCOUNT_IDS | wc -w`

echo >> $OUTFILE
echo "# Found $ACCOUNT_COUNT accounts to import" >> $OUTFILE

> add_to_tfvars.txt

for id in $ACCOUNT_IDS ; do

	if [[ $id == $PAYER_ID ]] ; then
		continue
	fi

	if [[ $id == $SECURITY_ACCOUNT_ID ]] ; then
		continue
	fi

    cat accounts.json | jq '.Accounts[]|select(.Id | contains("'$id'"))' > $id.json

    cat <<EOF >> add_to_tfvars.txt
    "$id" = {
      account_name  = "`cat $id.json | jq -r .Name`"
      account_email = "`cat $id.json | jq -r .Email`"
    }
EOF

cat <<EOF >> $OUTFILE
import {
  to =  module.organization.module.accounts["$id"].aws_organizations_account.account
  id = "$id"
}
EOF

   rm $id.json

done

cat <<EOF >> $OUTFILE

#
# If you have a pre-existing CloudTrail or billing buckets, add them here.
#
# import {
#   to = module.organization.aws_s3_bucket.cloudtrail_bucket[0]
#   id = "CHANGEME_TO_EXISTING_BUCKETNAME"
# }
# import {
#   to = module.organization.aws_s3_bucket.billing_logs[0]
#   id = "CHANGEME_TO_EXISTING_BUCKETNAME"
# }

#
# If you have a pre-existing Audit Role stackset, add it here
#
# import {
#   to = module.organization.aws_cloudformation_stack_set.audit_role[0]
#   id = "audit-role-stackset,DELEGATED_ADMIN"
# }

EOF

rm accounts.json