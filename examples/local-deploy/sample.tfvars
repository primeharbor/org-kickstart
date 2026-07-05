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
  # Manage the Terraform state bucket (backend_bucket) with Terraform. The bucket must already
  # exist; it is adopted via the import block in main.tf. Set false to leave it unmanaged.
  manage_state_bucket = true
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
  sso_instance_region               = "us-east-1"
  sso_start_url                     = "https://yourorg.awsapps.com/start"
  deploy_audit_role                 = true
  audit_role_name                   = "security-audit"
  audit_role_stack_set_template_url = "https://s3.amazonaws.com/pht-cloudformation/aws-account-automation/AuditRole-Template.yaml"
  declarative_policy_bucket_name    = "account-status-report-bucket-example"
  vpc_flowlogs_bucket_name          = "example-kickstart-flowlogs"
  macie_bucket_name                 = "example-kickstart-macie-findings"
  default_close_on_deletion         = true

  security_account = {
    delegated_admin         = ["fms.amazonaws.com"]
    monthly_budget_amount   = 20
    budget_alert_recipients = ["soc@example.com"]
  }

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
      account_name             = "example-kickstart-dev"
      account_email            = "aws+kickstart-dev@example.com"
      monthly_budget_amount    = 35
      budget_alert_recipients  = ["test@example.com"]
      service_control_policies = ["DenyProductionAccess"]
    }
    it = {
      account_name          = "example-kickstart-it"
      account_email         = "aws+kickstart-it@example.com"
      monthly_budget_amount = 150
    }

    sso = {
      account_name              = "example-sso"
      account_email             = "aws+ssot@example.com"
      parent_ou_name            = "Governance"
      delegated_admin           = ["sso.amazonaws.com"]
      resource_control_policies = ["BlockS3ExternalAccess"]
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

  aws_service_access_principals_to_exclude = [
    "ipam.amazonaws.com"
  ]

  aws_service_access_principals_to_enable = [
    "securitylake.amazonaws.com",
  ]

  organization_policy_types_to_exclude = [
    "TAG_POLICY"
  ]

  service_control_policies = {
    deny_root = {
      policy_name        = "DenyRoot"
      policy_description = "Denies use of root user"
      policy_json_file   = "policies/DenyRootSCP.json"
      # Lack of policy_target implies root
    }
    suspended_ou = {
      policy_name        = "SuspendedAccounts"
      policy_description = "Denies all activity in accounts in the SuspendedOU"
      policy_json_file   = "policies/SuspendedAccountsPolicy.json.tftpl"
      policy_targets     = ["Suspended"]
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
      policy_targets     = ["Workloads", "Sandbox"]
      policy_vars = {
        allowed_regions = ["us-east-1", "eu-west-1"]
        audit_role_name = "security-audit"
      }
    }

    workload_deny_instancetypes = {
      policy_name        = "DenyInstanceTypes"
      policy_description = "Deny access to unapproved Instance Types"
      policy_json_file   = "policies/DenyUnapprovedInstanceTypes.json"
      policy_targets     = ["Workloads", "Sandbox"]
    }

    workload_deny_services = {
      policy_name        = "DenyServices"
      policy_description = "Deny access to unapproved Services"
      policy_json_file   = "policies/DenyUnapprovedServices.json"
      policy_targets     = ["Workloads", "Sandbox"]
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

    permit_public_snapshot_ami = {
      policy_name        = "Permit_Public_AMI_Snapshots"
      policy_description = "Permit the public sharing of all EBS Snapshots or AMIs"
      policy_json_file   = "policies/EC2ImageSnapshotBPA_ALLOW_DCP.json"
      policy_type        = "DECLARATIVE_POLICY_EC2"
      do_not_attach      = true
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


  # These stacks are automatically deployed to the AWS Payer Account.
  # Set exactly one of template_file (local path, relative to path.root) or
  # template_url (S3/HTTPS URL). Optional: regions (defaults to the base
  # org-kickstart region), timeout_in_minutes (default 15), on_failure
  # (DO_NOTHING|ROLLBACK|DELETE, default DO_NOTHING).
  payer_cloudformation_stacks = {
    billing_alerts = {
      stack_name    = "slack_billing_alerts"
      template_file = "cloudformation/slack-Template.yaml"
      regions       = ["us-east-1"]
      parameters = {
        pExecutionRate      = "cron(0 09 * * ? *)"
        pEventInput         = <<-EOT
          {
            "threshold": "10",
            "alert_percent": "20"
          }
        EOT
        pSlackWebhookSecret = "SlackWebHook"
        pRuleState          = "ENABLED"
        pAccountDescription = "My-Payer"
      }
    }
  }

  # These stacks are automatically deployed to the Security Account using the
  # OrganizationAccountAccessRole. Same schema as payer_cloudformation_stacks.
  security_account_stacks = {
    findings_processor = {
      stack_name    = "security-findings-processor"
      template_file = "cloudformation/findings-processor-Template.yaml"
      regions       = ["us-east-1"]
      parameters = {
        pSlackWebhookSecret = "SlackWebHook"
        pSeverityThreshold  = "MEDIUM"
      }
    }
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

  budget_defaults = {
    alert_recipients      = ["finance@example.com"]
    currency              = "USD"
    warning_percentage    = 85
    organizational_budget = 75
  }

  datatrail = {
    bucket_name = "my-datatrail"
    trail_name  = "my-datatrail"
    enabled     = false
    excluded_buckets = [
      "example-kickstart-cloudtrail"
    ]
  }

  # Security Hub 2.0 configuration. Omit this block entirely to skip all Security Hub 2.0 setup.
  # When the block is present, create_cost_estimation_role, create_org_delegation_policy, and
  # enable_threat_detection all default to true if not explicitly set.
  security_hub_configuration = {
    enable_security_hub_2        = true   # Create the Security Hub 2.0 configuration
    create_cost_estimation_role  = true   # IAM role in payer account for cost estimator cross-account access
    create_org_delegation_policy = true   # Organization resource policy granting security account org-wide delegation
    enable_threat_detection      = true   # Enable Security Hub threat detection (future use)
    aggregation_region           = "us-east-1"
  }

}

backend_bucket = "org-kickstart-example"
