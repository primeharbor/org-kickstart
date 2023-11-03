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
      account_email = "aws+kickstart-dev@primeharbor.com"
    }
    it = {
      account_name  = "primeharbor-kickstart-it"
      account_email = "aws+kickstart-it@primeharbor.com"
    }
    sandbox = {
      account_name  = "primeharbor-kickstart-sandbox"
      account_email = "aws+kickstart-sandbox@primeharbor.com"
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

}