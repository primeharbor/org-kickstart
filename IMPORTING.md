# Importing

When using org-kickstart in an existing organization, a number of things need to be imported

The three required elements are the organization, organization manangement account, and the security account (if it exists).

You may also want to import the existing AWS accounts, the cloudtrail and billing buckets.

The script `import_org.sh` will generate both an import-org.tf file, and a TFVars segment for the AWS accounts (add to tf_vars.txt).

## Steps to import an existing org to the Org Kickstart module

1. Run the import_org.sh script
2. Review the import-org.tf file. Ensure everything looks right.
3. Add in a CloudTrail or Billing bucket
4. Review the SCPs you want to import
  `aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[].[Id,Name]' --output text`

At this point, it's recommended to run `make env=COMPANY tf-init tf-plan` locally until you're happy that the apply will not modify anything you don't want it to. You can adjust your tfvars file and disable creation of resources ahead of the first apply.

Once the first apply has occurred, enable the additional features you want in your org.


# Manually Adding things to import


## Organizational Units

Command to get the OUs:
```bash
ROOT_OU=`aws organizations list-roots --query Roots[0].Id --output text`
aws organizations list-organizational-units-for-parent --parent-id $ROOT_OU --query 'OrganizationalUnits[].[Id,Name]' --output text
```

The Import Block should look like:
```hcl
import {
  to = module.organization.aws_organizations_organizational_unit.TF_VARS_KEY
  id = "ou-1234567"
}
```

## SSO / Identity Center

To opt out of managing an existing Identity Center in org-kickstart you can set the `disable_sso_management` to true in the
tfvars file. This is probably recommended for all existing orgs, as you will want to manage Identity Center in a much more advanced way. All Org-Kickstart will do is ensure the admin group has admin access in every account.


To get the list of Groups:
```bash
IDENTITY_STORE_ID=`aws sso-admin list-instances --query Instances[0].IdentityStoreId --output text`
aws identitystore list-groups --identity-store-id $IDENTITY_STORE_ID
```

To get the correct Permission Set, it's recommended to use the [AWS Identity Center Console](https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/organization/permission-sets) and then set PERMISSION_SET_ARN in your shell. A permission set arn looks like `arn:aws:sso:::permissionSet/ssoins-CHANGEME/ps-CHANGEME`

To get the SSO Instance ARN:
```bash
aws sso-admin list-instances --query Instances[0].InstanceArn --output text
```

The Import HCL should look like:
```hcl

import {
  to = module.organization.aws_identitystore_group.admin_group
  id = "$IDENTITY_STORE_ID/$GROUP_ID"
}
import {
  to = module.organization.aws_ssoadmin_permission_set.admin_permission_set
  id = "$PERMISSION_SET_ARN,$SSO_INSTANCE_ARN"
}
import {
  to = module.organization.aws_ssoadmin_managed_policy_attachment.admin_policy_attachments
  id = "arn:aws:iam::aws:policy/AdministratorAccess,$PERMISSION_SET_ARN,$SSO_INSTANCE_ARN"
}
import {
  to = module.organization.module.security_account.aws_ssoadmin_account_assignment.account_group_assignment
  id = "<YOUR_GROUP_ID>,GROUP,$SECURITY_ACCOUNT_ID,AWS_ACCOUNT,$PERMISSION_SET_ARN,$SSO_INSTANCE_ARN"
}
import {
  to = module.organization.payer_account_group_assignment[0]
  id = "<YOUR_GROUP_ID>,GROUP,$PAYER_ACCOUNT_ID,AWS_ACCOUNT,$PERMISSION_SET_ARN,$SSO_INSTANCE_ARN"
}
```

## CloudTrail

You can attempt to import your existing CloudTrail.

List existing trails
```bash
aws cloudtrail list-trails --query Trails[].TrailARN --output text
```

```hcl
import {
  to = module.organization.aws_s3_bucket.cloudtrail_bucket[0]
  id = "CHANGEME_TO_EXISTING_BUCKETNAME"
}
import {
  to = module.organization.aws_cloudtrail.org_cloudtrail[0]
  id = "ARN_FROM_COMMAND_ABOVE"
}
```

## Service Control Policies

To get the list of Policy IDs, run:
```bash
aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[].[Id,Name]' --output text
```
To get the list of OUs for each policy:
```bash
aws organizations list-targets-for-policy --policy-id p-xxxxxx
```
Add to the TF Import File:
```hcl
import {
  to =  module.organization.module.scp["POLICY_BLOCK_IDENTIFIER_FROM_TFVARS"].aws_organizations_policy.scp
  id = "p-xxxxxx"
}
```
