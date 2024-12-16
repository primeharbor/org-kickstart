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
  organization_name                 = "org-kickstart"
  payer_name                        = "Example Test Payer"
  payer_email                       = "aws+kickstart-payer@example.com"
  security_account_name             = "example-kickstart-security"
  security_account_root_email       = "aws+kickstart-security@example.com"
  cloudtrail_bucket_name            = "example-kickstart-cloudtrail"
  cloudtrail_loggroup_name          = "CloudTrail/DefaultLogGroup"
  billing_data_bucket_name          = "example-kickstart-cur"
  cur_report_frequency              = "DAILY" # Valid options: DAILY, HOURLY, MONTHLY
  session_duration                  = "PT8H"
  admin_permission_set_name         = "AdministratorAccess"
  admin_group_name                  = "AllAdmins"
  disable_sso_management            = false
  deploy_audit_role                 = true
  audit_role_name                   = "security-audit"
  audit_role_stack_set_template_url = "https://s3.amazonaws.com/pht-cloudformation/aws-account-automation/AuditRole-Template.yaml"
  declarative_policy_bucket_name    = "account-status-report-bucket-example"
  vpc_flowlogs_bucket_name          = "example-kickstart-flowlogs"
  macie_bucket_name                 = "example-kickstart-macie-findings"

  organization_units = {

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
      account_name  = "example-kickstart-dev"
      account_email = "aws+kickstart-dev@example.com"
    }
    it = {
      account_name  = "example-kickstart-it"
      account_email = "aws+kickstart-it@example.com"
    }
    sandbox = {
      account_name  = "example-kickstart-sandbox"
      account_email = "aws+kickstart-sandbox@example.com"
      parent_ou_id  = "ou-yyyy-yyyyyyyy"

      # You can override the Primary Contact / Account Owner
      primary_contact = {
        full_name       = "Chris Farris"
        company_name    = "Fooli Media Services, LLC"
        address_line_1  = "1234 Main Street"
        address_line_2  = "Suite 101"
        city            = "Atlanta"
        state_or_region = "GA"
        postal_code     = "30332"
        country_code    = "US"
        email_address   = "aws@example.com"
        phone_number    = "+14041234567"
        website_url     = "https://example.com"
      }
    }
  }

  global_billing_contact = {
    name          = "Chris Farris"
    title         = "CFO"
    email_address = "billing@example.com"
    phone_number  = "+14041234567"
  }

  global_security_contact = {
    name          = "Chris Farris"
    title         = "Global CISO"
    email_address = "security@example.com"
    phone_number  = "+14041234567"
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

  resource_control_policies = {
    s3_data_perimeter = {
      policy_name        = "S3DataPerimeter"
      policy_description = "Restricts S3 to Principals inside the Org"
      policy_json_file   = "policies/RCP_S3DataPerimeter.json.tftpl"
      policy_vars = {
        org_id = "o-yyyyyy" # This needs to be hardcoded for reasons
      }
    }
  }

  declarative_policies = {
    deny_public_ami = {
      policy_name        = "Block_Public_AMIs"
      policy_description = "Deny the public sharing of all AMIs"
      policy_type        = "DECLARATIVE_POLICY_EC2"
      policy_json_file   = "policies/EC2ImageBPA_DCP.json"
      policy_targets     = ["Workloads", "Governance", "Suspended", "CoreIT"]
    }

    deny_public_snapshot = {
      policy_name        = "Block_Public_Snapshots"
      policy_description = "Deny the public sharing of all EBS Snapshots"
      policy_json_file   = "policies/EC2SnapshotBPA_DCP.json"
      policy_type        = "DECLARATIVE_POLICY_EC2"
      policy_targets     = ["Workloads", "Governance", "Suspended", "CoreIT"]
    }

    enable_imdsv2 = {
      policy_name        = "Enforce_IMDSv2"
      policy_description = "Enforce the usage of IMSv2 - Require Tokens, and set a hop limit of 2"
      policy_json_file   = "policies/EC2IMDSv2Enforce_DCP.json"
      policy_type        = "DECLARATIVE_POLICY_EC2"
      policy_targets     = ["Workloads", "Governance", "Suspended", "CoreIT"]
    }

  }

  security_services = {
    disable_guardduty   = false
    disable_securityhub = true
    disable_macie       = true
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

backend_bucket = "org-kickstart-example"
