# org-kickstart

Kickstart and manage your AWS Organization via Terraform via PrimeHarbor's opinionated version of Control Tower

## Getting setup

Overview
1. Make sure you've done all the artisinal steps in the console to enable AWS Organizations and AWS SSO. See [BOOTSTRAP.md]
2. Pick an environment name or code for your org install. Something like `pht` or `fooli`. Henceforth I'll refer to this as `$env`
2. Use the [CodePipeline-Template.yaml](CodePipeline-Template.yaml) CloudFormation Template to bootstrap the terraform state bucket and CodePipeline for GitOps management.
	1. `pip install cftdeploy`
	2. `cft-generate-manifest -m $env-Pipeline-Manifest.yaml -t CodePipeline-Template.yaml`
	3. Edit the $env-Pipeline-Manifest.yaml file setting the important parameters and StackName
	4. `cft-deploy -m $env-Pipeline-Manifest.yaml`
3. Copy the [sample.tfbackend](sample.tfbackend) to `$env.tfbackend`. Update the bucket with the name selected in the manifest above.
3. Copy the [sample.tfvars](sample.tfvars) to `$env.tfvars`. Update all the things.


## First Deploy - New Organization

1. Export the name of the environment for future command, and then run terraform init
  ```bash
  export env=FOO
  make tf-init
  ```
2. You must import the organizational management account and the organization that was created via ClickOps
  ```bash
  ./scripts/import-org.sh
  cat import-org.tf
  ```
3. Review the import-org.tf file for accuracy.
4. Run the teraform plan to create the security account (if one doesn't already exist)
  ```bash
  terraform plan -out=${env}-terraform.tfplan -no-color -var-file="${env}.tfvars" -target module.organization.module.security_account
  ```
5. Create the security account
  ```bash
  make tf-apply
  ```
6. Disable the creations of All AWS Accounts and Custom SCPs in your TF Vars file
  1. Comment out the `accounts = {}` block
  2. Comment out the `service_control_policies = {}` block
  3. We will re-enable them after the first apply.
  4. Delete the `security_services.tf` file on the first run.
7. Run the full terraform plan
  ```bash
  make tf-plan
  ```
8. Run the first terraform apply
  ```bash
  make tf-apply
  ```
9. Generate the multi-region files and re-run the plan:
  ```bash
  ./scripts/generate_regions.sh
  make tf-init
  make tf-plan
  ```



If you see the following error:
```
Error: listing Organizations Accounts for parent (r-117h) and descendants: AccessDeniedException: You don't have permissions to access this resource.
```
You need to delete the `security_services.tf`, apply the changes, then re-generate the file from the `generate_regions.sh` script. The Security Account _must_ have delegated admin enabled before this resources can be plan'ed or apply'd


## Post Deploy

1. Clean up AWS Identity Center:
  1. In the AWS Console: Login to the organization management as `TempAdministratorAccess`
  1. Add yourself to the Admin group defined in `admin_group_name`
  2. Log back into the organization management as `AdministratorAccess`
  2. Remove the assignment for TempAdministratorAccess from the Organization Management Account
  3. Delete permission set "TempAdministratorAccess"


---
# Older notes follow. Ignore this

**Add Yourself to the allAdmins Group afterward**
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-orgs-activate-trusted-access.html
https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacksets


make tf-plan

Things that _have_ to be imported
payer  module.organization.aws_organizations_account.payer
org module.organization.aws_organizations_organization.org


export ORG_ID=`aws organizations describe-organization --query Organization.Id --output text`
./tf-import.sh module.organization.aws_organizations_organization.org $ORG_ID

terraform plan -out=${env}-terraform.tfplan -no-color -var-file="${env}.tfvars" --target module.organization.data.aws_organizations_organizational_unit_descendant_accounts.accounts



module.organization.module.security_account.aws_organizations_account.account

  terraform plan -out=${env}-terraform.tfplan -no-color -var-file="${env}.tfvars" --target module.organization.module.security_account.aws_organizations_account.account
  make tf-apply


### Importing existing accounts

The [generate_accounts.sh](generate_accounts.sh) will list all of the accounts in your organization and create the necessary tfvars entry and `terraform import` commands. Run that script and it will create two files:
* add_to_tfvars.txt - a preformated list of account definitions to add to the `accounts` section of the $env.tfvars file.
* import_accounts.sh - a bash script that will perform the terraform import commands.

**Important** Remove both the SECURITY and PAYER accounts from both the organization.accounts block and from the import_accounts.sh script. These two accounts are _not_ managed with all the other workload accounts.


## Initial run
The first run is best done locally (not via CodePipeline), since multiple existing resources will probably need to be imported.

It's best to disable all the optional management during the first import.
Comment out the following in main.tf `module "organization" {}`

```hcl
cloudtrail_bucket_name = var.organization["cloudtrail_bucket_name"]
global_billing_contact  = var.organization["global_billing_contact"]
global_security_contact = var.organization["global_security_contact"]
billing_data_bucket_name = var.organization["billing_data_bucket_name"]
cur_report_frequency     = var.organization["cur_report_frequency"]
service_control_policies = var.organization["service_control_policies"]
```

Disable SSO and Audit Role in your main.tf `module "organization" {}`
```hcl
disable_sso_management    = true
deploy_audit_role = false
```

Disable all the security services to start with in your tfvars file:
```hcl
  security_services = {
    disable_guardduty   = true
    disable_securityhub = true
    disable_macie 		= true
    disable_inspector	= true
  }
```


**Import existing required resources**
Set the SECURITY_ACCOUNT and PAYER_ACCOUNT variables to their respective 12 digit AWS account IDs
```bash
SECURITY_ACCOUNT=222222222222
PAYER_ACCOUNT=111111111111
ORG=`aws organizations describe-organization --query Organization.Id --output text`
make env=$env tf-init
./tf-import.sh module.organization.module.security_account.aws_organizations_account.account $SECURITY_ACCOUNT
./tf-import.sh module.organization.aws_organizations_account.payer $PAYER_ACCOUNT
./tf-import.sh module.organization.aws_organizations_organization.org $ORG
./tf-import.sh module.organization.aws_organizations_delegated_administrator.cloudformation $SECURITY_ACCOUNT/member.org.stacksets.cloudformation.amazonaws.com
./tf-import.sh module.organization.aws_organizations_delegated_administrator.sso $SECURITY_ACCOUNT/sso.amazonaws.com

# Include any pre-existing Organizational units here. If there are none, then org-kickstart will create them.
./tf-import.sh module.organization.aws_organizations_organizational_unit.governance_ou ou-rrrr-uuuuuuu
./tf-import.sh module.organization.aws_organizations_organizational_unit.workloads_ou ou-rrrr-uuuuuuu
./tf-import.sh module.organization.aws_organizations_organizational_unit.sandbox_ou ou-rrrr-uuuuuuu
./tf-import.sh module.organization.aws_organizations_organizational_unit.suspended_ou ou-rrrr-uuuuuuu



# Import all the AWS accounts
bash ./import_accounts.sh
```

You may see the following error, which means one of the above imports doesn't yet exist (typically on the delegated_administrator).
>	│ Error: Cannot import non-existent remote object

These can be ignored as org-kickstart will create what is missing.

Next run a terraform plan to see what will be created, altered, or destroyed. Stop here if anything will be destroyed.

```
make tf-plan
Plan: 6 to add, 27 to change, 0 to destroy.
```

To analyze what may happen:
```bash
make tf-show | grep "will be created"
  # module.organization.aws_organizations_delegated_administrator.sso will be created
  # module.organization.aws_organizations_organizational_unit.sandbox_ou will be created
  # module.organization.aws_organizations_organizational_unit.suspended_ou will be created
  # module.organization.aws_organizations_organizational_unit.workloads_ou will be created
  # module.organization.aws_organizations_policy.ai_policy will be created
  # module.organization.aws_organizations_policy_attachment.ai_policy_root will be created

make tf-show | grep "will be updated"
  # module.organization.aws_organizations_account.payer will be updated in-place
  # module.organization.aws_organizations_organization.org will be updated in-place
  # module.organization.aws_organizations_organizational_unit.governance_ou will be updated in-place
  # module.organization.module.accounts["xxxxxxxxxxxx"].aws_organizations_account.account will be updated in-place
  # module.organization.module.accounts["yyyyyyyyyyyy"].aws_organizations_account.account will be updated in-place
  # module.organization.module.accounts["zzzzzzzzzzzz"].aws_organizations_account.account will be updated in-place
  ...
  # module.organization.module.security_account.aws_organizations_account.account will be updated in-place

```