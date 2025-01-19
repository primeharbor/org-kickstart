# Org-Kickstart

Copyright 2023 Chris Farris <chris@primeharbor.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0, < 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.80.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.80.0 |
| <a name="provider_aws.security-account"></a> [aws.security-account](#provider\_aws.security-account) | >= 5.80.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_accounts"></a> [accounts](#module\_accounts) | ./modules/account | n/a |
| <a name="module_billing_alerts"></a> [billing\_alerts](#module\_billing\_alerts) | ./modules/billing_alerts | n/a |
| <a name="module_declarative_policies"></a> [declarative\_policies](#module\_declarative\_policies) | ./modules/declarative_policies | n/a |
| <a name="module_rcp"></a> [rcp](#module\_rcp) | ./modules/rcp | n/a |
| <a name="module_scp"></a> [scp](#module\_scp) | ./modules/scp | n/a |
| <a name="module_security_account"></a> [security\_account](#module\_security\_account) | ./modules/account | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_account_alternate_contact.billing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_alternate_contact.operations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_alternate_contact.security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_primary_contact.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_primary_contact) | resource |
| [aws_budgets_budget.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |
| [aws_cloudformation_stack.account_factory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_cloudformation_stack.audit_role_payer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_cloudformation_stack_set.audit_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set_instance.audit_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_cloudtrail.org_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_log_group.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cur_report_definition.cur_report_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cur_report_definition) | resource |
| [aws_iam_organizations_features.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_organizations_features) | resource |
| [aws_iam_role.cloudtrail_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudtrail_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_identitystore_group.admin_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group) | resource |
| [aws_kms_alias.macie_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.macie_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.macie_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_organizations_account.payer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_delegated_administrator.cloudformation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_organizations_delegated_administrator.securityhub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_organizations_organizational_unit.custom_ous](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.governance_ou](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.sandbox_ou](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.suspended_ou](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.workloads_ou](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_policy.ai_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.ai_policy_root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_s3_bucket.billing_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.cloudtrail_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.declarative_policy_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.macie_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.vpc_flowlogs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_notification.bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_ownership_controls.cloudtrail_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.declarative_policy_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.macie_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.vpc_flowlogs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.allow_billing_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.cloudtrail_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.declarative_policy_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.macie_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.vpc_flowlogs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.billing_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.cloudtrail_bucket_bpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.declarative_policy_bucket_bpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.macie_bucket_bpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.vpc_flowlogs_bucket_bpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.macie_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.cloudtrail_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.declarative_policy_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.macie_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.vpc_flowlogs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.account_factory_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_securityhub_account.payer_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_account.security_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_configuration_policy.no_enabled_standards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy) | resource |
| [aws_securityhub_configuration_policy_association.root_ou](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy_association) | resource |
| [aws_securityhub_finding_aggregator.regional_aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_securityhub_organization_admin_account.delegated_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account) | resource |
| [aws_securityhub_organization_configuration.security_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration) | resource |
| [aws_sns_topic.cloudtrail_s3_notification_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_ssoadmin_account_assignment.payer_account_group_assignment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment) | resource |
| [aws_ssoadmin_managed_policy_attachment.admin_policy_attachments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_managed_policy_attachment) | resource |
| [aws_ssoadmin_permission_set.admin_permission_set](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set) | resource |
| [aws_billing_service_account.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/billing_service_account) | data source |
| [aws_iam_policy_document.allow_billing_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_s3_notification_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.declarative_policy_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.macie_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_flowlogs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_organizational_units.all_ous](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_units) | data source |
| [aws_ssoadmin_instances.identity_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_configurator"></a> [account\_configurator](#input\_account\_configurator) | Serverless Application to configure new accounts. See https://github.com/primeharbor/pht-account-configurator | <pre>object({<br/>    account_factory_config_file = string<br/>    template                    = string<br/>  })</pre> | `null` | no |
| <a name="input_accounts"></a> [accounts](#input\_accounts) | AWS accounts to provision in the organization. | <pre>map(<br/>    object({<br/>      account_name    = string<br/>      account_email   = string<br/>      delegated_admin = optional(list(string), [])<br/>      operations_contact = optional(object({<br/>        name          = string<br/>        title         = string<br/>        email_address = string<br/>        phone_number  = string<br/>      }))<br/>      primary_contact = optional(object({<br/>        full_name          = string<br/>        company_name       = optional(string)<br/>        address_line_1     = string<br/>        address_line_2     = optional(string)<br/>        address_line_3     = optional(string)<br/>        city               = string<br/>        district_or_county = optional(string)<br/>        state_or_region    = optional(string)<br/>        postal_code        = string<br/>        country_code       = string<br/>        phone_number       = string<br/>        website_url        = optional(string)<br/>      }))<br/>      parent_ou_name          = optional(string, "Workloads")<br/>      monthly_budget_amount   = optional(number, 0)<br/>      budget_alert_recipients = optional(list(string), [])<br/>    })<br/>  )</pre> | n/a | yes |
| <a name="input_admin_group_name"></a> [admin\_group\_name](#input\_admin\_group\_name) | Name of the Identity Store Group with all the admin users | `string` | `"AllAdmins"` | no |
| <a name="input_admin_permission_set_name"></a> [admin\_permission\_set\_name](#input\_admin\_permission\_set\_name) | Name of the Default Admin Permission Set to Create | `string` | `"AdministratorAccess"` | no |
| <a name="input_audit_role_name"></a> [audit\_role\_name](#input\_audit\_role\_name) | Name of the AuditRole to deploy | `string` | `"security-audit"` | no |
| <a name="input_audit_role_stack_set_template_url"></a> [audit\_role\_stack\_set\_template\_url](#input\_audit\_role\_stack\_set\_template\_url) | URL that points to the Audit Role Policy Template | `string` | `null` | no |
| <a name="input_backend_bucket"></a> [backend\_bucket](#input\_backend\_bucket) | Name of the S3 bucket used for the CloudFormation stacks and Terraform state backend | `string` | n/a | yes |
| <a name="input_billing_alerts"></a> [billing\_alerts](#input\_billing\_alerts) | Triggers for billing alerts and who should receive them. | <pre>object({<br/>    levels        = map(number)<br/>    subscriptions = list(string)<br/>  })</pre> | `null` | no |
| <a name="input_billing_data_bucket_name"></a> [billing\_data\_bucket\_name](#input\_billing\_data\_bucket\_name) | Name of the S3 Bucket for CUR reports. Set to null to disable CUR report generation. | `string` | `null` | no |
| <a name="input_budget_defaults"></a> [budget\_defaults](#input\_budget\_defaults) | Default values for AWS Budgets. Some settings can be overridden in the account definition. | <pre>object({<br/>    alert_recipients      = list(string)<br/>    currency              = string<br/>    warning_percentage    = number<br/>    organizational_budget = number<br/>  })</pre> | <pre>{<br/>  "alert_recipients": [],<br/>  "currency": "USD",<br/>  "organizational_budget": 0,<br/>  "warning_percentage": 85<br/>}</pre> | no |
| <a name="input_cloudtrail_bucket_name"></a> [cloudtrail\_bucket\_name](#input\_cloudtrail\_bucket\_name) | Name of the S3 Bucket to create to store CloudTrail events. Set to null to disable CloudTrail management | `string` | `null` | no |
| <a name="input_cloudtrail_loggroup_name"></a> [cloudtrail\_loggroup\_name](#input\_cloudtrail\_loggroup\_name) | Name of the CloudWatch Log Group in the payer account where CloudTrail will send its events. Set to null to disable CloudTrail to CloudWatch Logs. | `string` | `null` | no |
| <a name="input_cur_report_frequency"></a> [cur\_report\_frequency](#input\_cur\_report\_frequency) | Frequency CUR reports should be delivered (DAILY, HOURLY, MONTHLY). Set to NONE to disable | `string` | `"NONE"` | no |
| <a name="input_declarative_policies"></a> [declarative\_policies](#input\_declarative\_policies) | Map of Declarative Policies to create and attach. | <pre>map(object({<br/>    policy_name        = string<br/>    policy_description = string<br/>    policy_json_file   = string<br/>    policy_targets     = optional(list(string), ["Root"])<br/>    policy_vars        = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_declarative_policy_bucket_name"></a> [declarative\_policy\_bucket\_name](#input\_declarative\_policy\_bucket\_name) | Name of S3 Bucket for Declarative Policy Reports. Set to null to disable Declarative Policy Reports. | `string` | `null` | no |
| <a name="input_default_close_on_deletion"></a> [default\_close\_on\_deletion](#input\_default\_close\_on\_deletion) | If set, the AWS Account will be closed when it's removed from org-kickstart. Set this with caution. | `bool` | `false` | no |
| <a name="input_deploy_audit_role"></a> [deploy\_audit\_role](#input\_deploy\_audit\_role) | Boolean to determine if org-kickstart should manage a Security Audit Role. Set to false to disable the creation of an Audit Role stackset. | `bool` | `true` | no |
| <a name="input_disable_sso_management"></a> [disable\_sso\_management](#input\_disable\_sso\_management) | Set to true to disable creating a default Admin Permission Set in Identity Center. | `bool` | `false` | no |
| <a name="input_global_billing_contact"></a> [global\_billing\_contact](#input\_global\_billing\_contact) | Billing alternate contact to be applied to all accounts. | <pre>object({<br/>    name          = string<br/>    title         = string<br/>    email_address = string<br/>    phone_number  = string<br/>  })</pre> | `null` | no |
| <a name="input_global_operations_contact"></a> [global\_operations\_contact](#input\_global\_operations\_contact) | Default operations alternate contact to be applied to all accounts. Can be overridden in account definition. | <pre>object({<br/>    name          = string<br/>    title         = string<br/>    email_address = string<br/>    phone_number  = string<br/>  })</pre> | `null` | no |
| <a name="input_global_primary_contact"></a> [global\_primary\_contact](#input\_global\_primary\_contact) | Default primary account owner to be applied to all accounts. Can be overridden in account definition. | <pre>object({<br/>    full_name          = string<br/>    company_name       = optional(string)<br/>    address_line_1     = string<br/>    address_line_2     = optional(string)<br/>    address_line_3     = optional(string)<br/>    city               = string<br/>    district_or_county = optional(string)<br/>    state_or_region    = optional(string)<br/>    postal_code        = string<br/>    country_code       = string<br/>    phone_number       = string<br/>    website_url        = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_global_security_contact"></a> [global\_security\_contact](#input\_global\_security\_contact) | Security alternate contact to be applied to all accounts | <pre>object({<br/>    name          = string<br/>    title         = string<br/>    email_address = string<br/>    phone_number  = string<br/>  })</pre> | `null` | no |
| <a name="input_macie_bucket_name"></a> [macie\_bucket\_name](#input\_macie\_bucket\_name) | Name of the S3 Bucket to create to store Macie Findings. Set to null to skip creation | `string` | `null` | no |
| <a name="input_organization_name"></a> [organization\_name](#input\_organization\_name) | Name of the Organization. This is used for resource prefixes and general reference | `string` | n/a | yes |
| <a name="input_organization_units"></a> [organization\_units](#input\_organization\_units) | Map of OUs to create. | <pre>map(<br/>    object({<br/>      name             = string<br/>      is_child_of_root = optional(bool) # This is ignored, it is retained for backwards compatibility<br/>      parent_id        = optional(string)<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_payer_email"></a> [payer\_email](#input\_payer\_email) | Root Email address for the Organization Management account | `string` | n/a | yes |
| <a name="input_payer_name"></a> [payer\_name](#input\_payer\_name) | Name of the Organization Management account | `string` | `"AWS Payer"` | no |
| <a name="input_resource_control_policies"></a> [resource\_control\_policies](#input\_resource\_control\_policies) | Map of RCPs to create and attach. | <pre>map(<br/>    object({<br/>      policy_name        = string<br/>      policy_description = string<br/>      policy_json_file   = string<br/>      policy_targets     = optional(list(string), ["Root"])<br/>      policy_vars        = optional(map(string), {})<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_security_account"></a> [security\_account](#input\_security\_account) | Settings for the Security Account. | <pre>object({<br/>    # These will move from the main module to here at some point.<br/>    # account_name    = string<br/>    # account_email   = string<br/>    delegated_admin = optional(list(string), [])<br/>    operations_contact = optional(object({<br/>      name          = string<br/>      title         = string<br/>      email_address = string<br/>      phone_number  = string<br/>    }))<br/>    primary_contact = optional(object({<br/>      full_name          = string<br/>      company_name       = optional(string)<br/>      address_line_1     = string<br/>      address_line_2     = optional(string)<br/>      address_line_3     = optional(string)<br/>      city               = string<br/>      district_or_county = optional(string)<br/>      state_or_region    = optional(string)<br/>      postal_code        = string<br/>      country_code       = string<br/>      phone_number       = string<br/>      website_url        = optional(string)<br/>    }))<br/>    monthly_budget_amount   = optional(number, 0)<br/>    budget_alert_recipients = optional(list(string), [])<br/>  })</pre> | n/a | yes |
| <a name="input_security_account_name"></a> [security\_account\_name](#input\_security\_account\_name) | Name of the Security Account | `string` | `"Security Account"` | no |
| <a name="input_security_account_root_email"></a> [security\_account\_root\_email](#input\_security\_account\_root\_email) | Root Email address for the security account | `string` | n/a | yes |
| <a name="input_security_services"></a> [security\_services](#input\_security\_services) | Explicitly disable or not manage a security service | `map(string)` | <pre>{<br/>  "disable_guardduty": "false",<br/>  "disable_inspector": "false",<br/>  "disable_macie": "false",<br/>  "disable_securityhub": "false"<br/>}</pre> | no |
| <a name="input_service_control_policies"></a> [service\_control\_policies](#input\_service\_control\_policies) | Map of SCPs to create and attach. | <pre>map(<br/>    object({<br/>      policy_name        = string<br/>      policy_description = string<br/>      policy_json_file   = string<br/>      policy_targets     = optional(list(string), ["Root"])<br/>      policy_vars        = optional(map(string), {})<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_session_duration"></a> [session\_duration](#input\_session\_duration) | Admin Permission Set Session Duration | `string` | `"PT8H"` | no |
| <a name="input_tag_set"></a> [tag\_set](#input\_tag\_set) | Default map of tags to be applied to all resources via all providers | `map(string)` | `{}` | no |
| <a name="input_vpc_flowlogs_bucket_name"></a> [vpc\_flowlogs\_bucket\_name](#input\_vpc\_flowlogs\_bucket\_name) | Name of the S3 Bucket to create to store VPC Flow Logs. Set to null to skip creation | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudtrail_cloudwatch_log_group"></a> [cloudtrail\_cloudwatch\_log\_group](#output\_cloudtrail\_cloudwatch\_log\_group) | ARN of the CloudWatch Log Group that has the CloudTrail Management Events |
| <a name="output_cloudtrail_s3_notification_topic"></a> [cloudtrail\_s3\_notification\_topic](#output\_cloudtrail\_s3\_notification\_topic) | ARN of the SNS Topic that receives S3 notifications of new CloudTrail event objects. |
| <a name="output_declarative_policy_bucket"></a> [declarative\_policy\_bucket](#output\_declarative\_policy\_bucket) | S3 Bucket used to store declarative policies |
| <a name="output_macie_key_arn"></a> [macie\_key\_arn](#output\_macie\_key\_arn) | ARN of the KMS Key used by Macie |
| <a name="output_org_id"></a> [org\_id](#output\_org\_id) | ID of the AWS Organization |
| <a name="output_org_name"></a> [org\_name](#output\_org\_name) | Name of the AWS Organization |
| <a name="output_ou_name_to_id"></a> [ou\_name\_to\_id](#output\_ou\_name\_to\_id) | Map of OU Names to OU IDs |
| <a name="output_security_account_id"></a> [security\_account\_id](#output\_security\_account\_id) | ID of the Security Account |
| <a name="output_sso_instance_arn"></a> [sso\_instance\_arn](#output\_sso\_instance\_arn) | AWS Identity Center Instance ARN managed by org-kickstart |
