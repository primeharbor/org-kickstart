# Importing

When using org-kickstart in an existing organization, a number of things need to be imported

The three required elements are the organization, organization manangement account, and the security account (if it exists).

You may also want to import the existing AWS accounts, the cloudtrail and billing buckets.

The script `import_org.sh` will generate both an import-org.tf file, and a TFVars segment for the AWS accounts (add to tf_vars.txt).

## Steps to import an existing org to the Org Kickstart module









## Vars

```bash
ENV=fooli
ROOT_OU=`aws organizations list-roots --query Roots[0].Id --output text`
SECURITY_ACCOUNT_ID=11111111111
IDENTITY_STORE_ID=`aws sso-admin list-instances --query Instances[0].IdentityStoreId --output text`
SSO_INSTANCE_ARN=`aws sso-admin list-instances --query Instances[0].InstanceArn --output text`
```




## Organization

Command to get the OUs:
` aws organizations list-organizational-units-for-parent --parent-id $ROOT_OU`

```bash
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_organizations_account.payer' PAYER_ACCOUNT_ID
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_organizations_organization.org' o-p9uexample
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_organizations_organizational_unit.governance_ou' ou-mlz5-example
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_organizations_organizational_unit.sandbox_ou' ou-mlz5-example
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_organizations_organizational_unit.suspended_ou' ou-mlz5-example
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_organizations_organizational_unit.workloads_ou' ou-mlz5-example

terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_organizations_delegated_administrator.cloudformation' $SECURITY_ACCOUNT_ID/member.org.stacksets.cloudformation.amazonaws.com
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_organizations_delegated_administrator.sso' $SECURITY_ACCOUNT_ID/sso.amazonaws.com

```

## Audit Role

Importing a stack-set tends to require recreating the stackset. To avoid managing the audit role via org-kickstart, set the `deploy_audit_role` to true in the organization module in `main.tf` like so:

```hcl
module "organization" {
  # source = "github.com/primeharbor/org-kickstart"
  source = "../org-kickstart"
  providers = {
    aws                  = aws
    aws.security_account = aws.security_account
  }

  deploy_audit_role = false # override managing audit role

...
}

```

Otherwise, you can try and import with these steps:

To get the Payer Stack Name:
`aws cloudformation describe-stacks --query Stacks[].StackName`
Then run:
`terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_cloudformation_stack.audit_role_payer' STACK_NAME `

To get the StackSet name:
`aws cloudformation list-stack-sets --query Summaries[].StackSetName`
Then run (replace `STACK_NAME` but leave DELEGATED_ADMIN as a literal):

```bash
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_cloudformation_stack_set.audit_role' STACK_NAME,DELEGATED_ADMIN
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_cloudformation_stack_set_instance.audit_role' STACK_NAME,$ROOT_OU,us-east-1,DELEGATED_ADMIN
```

## SSO / Identity Center

To opt out of managing an existing Identity Center in org-kickstart you can set the `disable_sso_management` to true in the organization module in `main.tf` like so:
```hcl
module "organization" {
  # source = "github.com/primeharbor/org-kickstart"
  source = "../org-kickstart"
  providers = {
    aws                  = aws
    aws.security_account = aws.security_account
  }

  disable_sso_management = true # don't manage SSO here

...
}
```

To get the list of Groups:
`aws identitystore list-groups --identity-store-id $IDENTITY_STORE_ID`

To get the correct Permission Set, it's recommended to use the [AWS Identity Center Console](https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/organization/permission-sets) and then set PERMISSION_SET_ARN in your shell. A permission set arn looks like `arn:aws:sso:::permissionSet/ssoins-CHANGEME/ps-CHANGEME`

```bash
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_identitystore_group.admin_group' $IDENTITY_STORE_ID/<YOUR_GROUP_ID>
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_ssoadmin_permission_set.admin_permission_set' $PERMISSION_SET_ARN,$SSO_INSTANCE_ARN
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_ssoadmin_managed_policy_attachment.admin_policy_attachments' arn:aws:iam::aws:policy/AdministratorAccess,$PERMISSION_SET_ARN,$SSO_INSTANCE_ARN
terraform import -var-file="${ENV}.tfvars" 'module.organization.module.security_account.aws_ssoadmin_account_assignment.account_group_assignment' <YOUR_GROUP_ID>,GROUP,$SECURITY_ACCOUNT_ID,AWS_ACCOUNT,$PERMISSION_SET_ARN,$SSO_INSTANCE_ARN
```

## CloudTrail

```bash
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_s3_bucket.cloudtrail_bucket'
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_s3_bucket_ownership_controls.cloudtrail_bucket'
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_s3_bucket_policy.cloudtrail_bucket_policy'
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_s3_bucket_public_access_block.cloudtrail_bucket_bpa'
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_s3_bucket_versioning.cloudtrail_bucket'
terraform import -var-file="${ENV}.tfvars" 'module.organization.aws_cloudtrail.org_cloudtrail[0]'

```




# Service Control Policies

To get the list of Policy IDs, run:
```bash
aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[].[Id,Name]' --output text
```
To get the list of Policies and attachments to import:
```bash
make env=$ENV tf-plan  | grep "will be created" | grep .aws_organizations_policy | awk '{print $2}'
```
To get the list of OUs for each policy:
```bash
aws organizations list-targets-for-policy --policy-id p-xxxxxx
```
To do the import:
```bash
terraform import -var-file="${ENV}.tfvars" 'module.organization.module.scp["workload_deny_instancetypes"].aws_organizations_policy.scp' p-xxxxxx

```

Attachements may throw errors.

	│ Error: creating Organizations Policy Attachment (ou-rrrrr-uuuuuuuu:p-xxxxxxx): DuplicatePolicyAttachmentException: A policy with the specified name and type already exists.
	│
	│   with module.organization.module.scp["workload_deny_services"].aws_organizations_policy_attachment.scp_attachment[0],
	│   on ../org-kickstart/modules/scp/main.tf line 44, in resource "aws_organizations_policy_attachment" "scp_attachment":
	│   44: resource "aws_organizations_policy_attachment" "scp_attachment" {

You can attach with:
```bash
terraform import -var-file="${ENV}.tfvars" 'module.organization.module.scp["workload_deny_services"].aws_organizations_policy_attachment.scp_attachment[0]' ou-rrrrr-uuuuuuuu:p-xxxxxxx
```


