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

organization = {
  organization_name           = "pht-kickstart"
  payer_name                  = "PrimeHarbor Test Payer"
  payer_email                 = "aws+kickstart-payer@primeharbor.com"
  security_account_name       = "primeharbor-kickstart-security"
  security_account_root_email = "aws+kickstart-security@primeharbor.com"
  cloudtrail_bucket_name      = "primeharbor-kickstart-cloudtrail"
  cloudtrail_loggroup_name    = "CloudTrail/DefaultLogGroup"
  billing_data_bucket_name    = "primeharbor-kickstart-cur"
  cur_report_frequency        = "DAILY" # Valid options: DAILY, HOURLY, MONTHLY
  session_duration            = "PT8H"
  admin_permission_set_name   = "AdministratorAccess"
  admin_group_name            = "AllAdmins"
  disable_sso_management      = false
  deploy_audit_role           = true
  audit_role_name             = "security-audit"
  audit_role_template_url     = "https://s3.amazonaws.com/pht-cloudformation/aws-account-automation/AuditRole-Template.yaml"
  vpc_flowlogs_bucket_name    = "primeharbor-kickstart-flowlogs"
  macie_bucket_name           = "primeharbor-kickstart-macie-findings"

  organizational_units = {
    "MemeFactories" = {
      name             = "MemeFactories"
      is_child_of_root = true
    }
    "CoreIT" = {
      name             = "CoreIT"
      is_child_of_root = true
    }
  }

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
      policy_json_file   = "policies/SuspendedAccountsPolicy.json.tftpl"
      policy_targets     = ["ou-xxxx-xxxxxxxx"]
      policy_vars = {
        audit_role_name = "security-audit"
      }
    }
    security_controls = {
      policy_name        = "DefaultSecurityControls"
      policy_description = "Base Security Controls for all accounts"
      policy_json_file   = "policies/SecurityControlsSCP.json.tftpl"
      policy_vars = {
        audit_role_name = "security-audit"
      }
    }

    workload_deny_regions = {
      policy_name        = "DenyRegions"
      policy_description = "Deny access to unapproved default regions"
      policy_json_file   = "policies/DisableRegionsPolicy.json.tftpl"
      policy_targets = [
        "ou-xxxx-xxxxxxxx", # Workloads
        "ou-yyyy-yyyyyyyy"  # Sandbox
      ]
      policy_vars = {
        allowed_regions = ["us-east-1", "eu-west-1"]
        audit_role_name = "security-audit"
      }
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

  global_primary_contact = {
    full_name      = "required"
    company_name   = "Optional"
    address_line_1 = "Required"
    # address_line_2  = "Optional"
    # address_line_3  = "Optional"
    city            = "Required"
    state_or_region = "GA"
    # district_or_county = "Optional"
    postal_code   = "Required"
    country_code  = "US"
    email_address = "Required"
    phone_number  = "+1-Required"
    # website_url     = "Optional"
  }

  security_services = {
    disable_guardduty   = false
    disable_securityhub = true
  }

  account_configurator = {
    template                    = "SEE README"
    account_factory_config_file = "account-config.yaml"
  }

  billing_alerts = {
    levels = {
      level1  = 10
      level2  = 20
      oh_shit = 100
    }
    subscriptions = [
      # "INSERT OTHER EMAILS TO GET BILLING ALERTS"
    ]
  }

}
