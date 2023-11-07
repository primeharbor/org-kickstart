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


# To use the SSO Imports, do a global search and replace on GROUP_ID, PERMSET_ID, INSTANCE_ID and uncomment the line

aws organizations list-accounts > accounts.json

ACCOUNT_IDS=`cat accounts.json | jq -r .Accounts[].Id`
ACCOUNT_COUNT=`echo $ACCOUNT_IDS | wc -w`

echo "Found $ACCOUNT_COUNT accounts to import"

> add_to_tfvars.txt

echo "#!/bin/bash -e" > import_accounts.sh

for id in $ACCOUNT_IDS ; do
    echo "Processing $id"
    cat accounts.json | jq '.Accounts[]|select(.Id | contains("'$id'"))' > $id.json

    cat <<EOF>> add_to_tfvars.txt
    "$id" = {
      account_name  = "`cat $id.json | jq -r .Name`"
      account_email = "`cat $id.json | jq -r .Email`"
    }
EOF

   echo "./tf-import.sh 'module.organization.module.accounts[\"$id\"].aws_organizations_account.account' $id" >> import_accounts.sh

   # echo "./tf-import.sh 'module.organization.module.accounts[\"$id\"].aws_ssoadmin_account_assignment.account_group_assignment[0]' GROUP_ID,GROUP,$id,AWS_ACCOUNT,arn:aws:sso:::permissionSet/ssoins-INSTANCE_ID/ps-PERMSET_ID,arn:aws:sso:::instance/ssoins-INSTANCE_ID >> import_accounts.sh


   rm $id.json

done

rm accounts.json