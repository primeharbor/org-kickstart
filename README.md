# org-kickstart

Kickstart and manage your AWS Organization via Terraform via PrimeHarbor's opinionated version of Control Tower

**Why?**
Control Tower sucks. It's a massive beast designed to support highly regulated companies with a cloud compliance framework that's more than what most companies need. Control Tower is hard to adjust, missing some key features, and lags behind AWS Best practices (it took a long time for Organization CloudTrail and GuardDuty Delegated Admin to be supported). You need a PhD in AWS Service Catalog to modify anything. It heavily leverages AWS Config, making it very expensive for small orgs.

Most orgs implement Control Tower because their AWS SA was told to tell them to, or because they needed some form of "account factory", and you can easily click a button to fully provision an account.

The Org Kickstart is intended to be a landing zone for the rest of us. Deployed in a brand new AWS account (after a [few Artisanal steps](BOOTSTRAP.md) are completed), it will deploy the good parts of ControlTower/Landing Zones with out all the expensive cruft.


## What is does
TODO

### Regions & Providers
Terraform sucks at allowing you to make calls across AWS regions. Org-Kickstart has pre-defined providers for all the default (non-opt-in) regions for both the payer and security account to be able to enable regional security services.

## Setup

You will need to create the new AWS account and enable SSO by hand prior to using org-kickstart. See the [BOOTSTRAP](BOOTSTRAP.md) documentation for what you need to do when deploying into a brand new AWS Account

See the examples/pipeline directory for a sample private repo that leverages this module.

Sample tfvars file:
```hcl

organization = {
  organization_name           = "pht-kickstart"
  payer_name                  = "PrimeHarbor Test Payer"
  payer_email                 = "aws+kickstart-payer@primeharbor.com"
  security_account_name       = "primeharbor-kickstart-security"
  security_account_root_email = "aws+kickstart-security@primeharbor.com"
  cloudtrail_bucket_name      = "primeharbor-kickstart-cloudtrail"
  billing_data_bucket_name    = "primeharbor-kickstart-cur"
  cur_report_frequency        = "DAILY" # Valid options: DAILY, HOURLY, MONTHLY

  session_duration          = "PT8H"
  admin_permission_set_name = "AdministratorAccess"

  accounts = {
    dev = {
      account_name  = "primeharbor-kickstart-dev"
      account_email = ""aws+kickstart-dev@primeharbor.com"
    }
    it = {
      account_name  = "primeharbor-kickstart-it"
      account_email = ""aws+kickstart-it@primeharbor.com"
    }
    sandbox = {
      account_name  = "primeharbor-kickstart-sandbox"
      account_email = ""aws+kickstart-sandbox@primeharbor.com"
      parent_ou_id  = "ou-yyyy-yyyyyyyy"
    }
  }

  global_billing_contact = {
    name          = "Chris Farris"
    title         = "CFO"
    email_address = "billing@primeharbor.com"
    phone_number  = "+14041234567"
  }

  global_security_contact = {
    name          = "Chris Farris"
    title         = "Global CISO"
    email_address = "security@primeharbor.com"
    phone_number  = "+14041234567"
  }

  service_control_policies = {
    deny_root = {
      policy_name        = "DenyRoot"
      policy_description = "Denies use of root user"
      policy_json_file   = "policies/DenyRootSCP.json"
    }
    suspended_ou = {
      policy_name        = "SuspendedAccounts"
      policy_description = "Denies all activity in accounts in the SuspendedOU"
      policy_json_file   = "policies/SuspendedAccountsPolicy.json"
      policy_targets     = ["ou-xxxx-xxxxxx"]
    }
    security_controls = {
      policy_name        = "DefaultSecurityControls"
      policy_description = "Base Security Controls for all accounts"
      policy_json_file   = "policies/SecurityControlsSCP.json"
    }

    workload_deny_regions = {
      policy_name        = "DenyRegions"
      policy_description = "Deny access to unapproved default regions"
      policy_json_file   = "policies/DisableRegionsPolicy.json"
      policy_targets = [
        "ou-xxxx-xxxxxxxx", # Workloads
        "ou-yyyy-yyyyyyyy"  # Sandbox
      ]
    }

    workload_deny_instancetypes = {
      policy_name        = "DenyInstanceTypes"
      policy_description = "Deny access to unapproved Instance Types"
      policy_json_file   = "policies/DenyUnapprovedInstanceTypes.json"
      policy_targets = [
        "ou-xxxx-xxxxxxxx", # Workloads
        "ou-yyyy-yyyyyyyy"  # Sandbox
      ]
    }

    workload_deny_services = {
      policy_name        = "DenyServices"
      policy_description = "Deny access to unapproved Services"
      policy_json_file   = "policies/DenyUnapprovedServices.json"
      policy_targets = [
        "ou-xxxx-xxxxxxxx", # Workloads
        "ou-yyyy-yyyyyyyy"  # Sandbox
      ]
    }
  }

  security_services = {
    disable_guardduty   = true
    disable_securityhub = true
    disable_macie       = true
    disable_inspector   = true
  }

}
```

tfbackend file:
```
bucket="org-kickstart-13456789012"
key="org-kickstart.tfstate"
```

## Using with an existing org
This can be used with an existing org. See [IMPORTING](IMPORTING.md) for more on how to do that. There are a number of things that can be disabled if you're doing something more complex than org-kickstart will handle.

1. Disable CloudTrail management by setting `cloudtrail_bucket_name = null`
2. Disable AWS SSO with `disable_sso_management = true`
3. Disable managing the Audit Role Stackset with `deploy_audit_role = false`



## Prior Art
https://github.com/george-richardson/terraform-aws-personal-org
https://github.com/chris-qa-org/terraform-aws-organzation-and-sso/tree/main/examples/accounts-and-permission-assignments


## Future work
1. Got the GuardDuty per-region stuff working for payer/security account. Now do the other services.
2. Deletion of Default VPCs would be nice.
  1. This might best be a stepfunction/lambda in the payer leveraging OrganizationAccountAccessRole
  2. revisit the idea of setting BPA, EBS Encryption and other fast-fixes
3. Billing Alarms are critical.
4. Global Operational Contact.
5. Global Account Contact.
6. Setup arbitrary OUs, beyond the basic AWS recommended ones.
7. revisit the SCPs in my pet-ControlTower for other best practices to steal.
8. Figure out if AWS Config Recorder/etc support should be an optional part of this
9. Account Import Script
10. Make it work with GitOps & Code Pipeline
10. Publish to Terraform Registry
11. More AWS Identity Center customization.