## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_account_alternate_contact.billing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_alternate_contact.operations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_alternate_contact.security](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_alternate_contact) | resource |
| [aws_account_primary_contact.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/account_primary_contact) | resource |
| [aws_budgets_budget.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |
| [aws_organizations_account.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_delegated_administrator.delegated_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_organizations_policy_attachment.dp_ec2_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.rcp_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.scp_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_ssoadmin_account_assignment.account_group_assignment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment) | resource |
| [aws_organizations_policies.dp_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_policies) | data source |
| [aws_organizations_policies.rcps](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_policies) | data source |
| [aws_organizations_policies.scps](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_policies) | data source |
| [aws_organizations_policy.dp_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_policy) | data source |
| [aws_organizations_policy.rcps](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_policy) | data source |
| [aws_organizations_policy.scps](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_policy) | data source |
| [aws_ssoadmin_instances.identity_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_email"></a> [account\_email](#input\_account\_email) | Root Email Address to Create | `string` | n/a | yes |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | Name of the AWS Account to Create | `string` | n/a | yes |
| <a name="input_admin_group_id"></a> [admin\_group\_id](#input\_admin\_group\_id) | ID of the Identity Center Admin Group | `string` | n/a | yes |
| <a name="input_admin_permission_set_arn"></a> [admin\_permission\_set\_arn](#input\_admin\_permission\_set\_arn) | Arn of the Identity Center Permission Set | `string` | n/a | yes |
| <a name="input_billing_contact"></a> [billing\_contact](#input\_billing\_contact) | The Billing Alternate Contact to apply to this account. | `any` | `null` | no |
| <a name="input_budget_alert_recipients"></a> [budget\_alert\_recipients](#input\_budget\_alert\_recipients) | List of email addresses to get Buget Alerts | `list(string)` | `[]` | no |
| <a name="input_declarative_policies_ec2"></a> [declarative\_policies\_ec2](#input\_declarative\_policies\_ec2) | List of Declarative Policy Names that are directly applied to this AWS Account. Policies must be created before they can be referenced. | `list(string)` | `[]` | no |
| <a name="input_default_close_on_deletion"></a> [default\_close\_on\_deletion](#input\_default\_close\_on\_deletion) | If set, the AWS Account will be closed when it's removed from org-kickstart. Set this with caution | `bool` | `false` | no |
| <a name="input_default_currency"></a> [default\_currency](#input\_default\_currency) | AWS Budgets Currency to measure in. | `string` | `"USD"` | no |
| <a name="input_delegated_admin"></a> [delegated\_admin](#input\_delegated\_admin) | List of AWS Services that this account is a delegated administrator for | `set(string)` | `[]` | no |
| <a name="input_disable_sso_management"></a> [disable\_sso\_management](#input\_disable\_sso\_management) | If set, the default SSO assignment won't be applied to this account | `bool` | `false` | no |
| <a name="input_monthly_budget_amount"></a> [monthly\_budget\_amount](#input\_monthly\_budget\_amount) | Amount in default\_currency that is set for this account | `number` | `0` | no |
| <a name="input_operations_contact"></a> [operations\_contact](#input\_operations\_contact) | The Operations Alternate Contact to apply to this account. | `any` | `null` | no |
| <a name="input_parent_ou_id"></a> [parent\_ou\_id](#input\_parent\_ou\_id) | ID of the Parent OU | `string` | n/a | yes |
| <a name="input_primary_contact"></a> [primary\_contact](#input\_primary\_contact) | The Primary Contact / Account Owner to apply to this account. | `any` | `null` | no |
| <a name="input_resource_control_policies"></a> [resource\_control\_policies](#input\_resource\_control\_policies) | List of RCP Names that are directly applied to this AWS Account. Policies must be created before they can be referenced. | `list(string)` | `[]` | no |
| <a name="input_security_contact"></a> [security\_contact](#input\_security\_contact) | The Security Alternate Contact to apply to this account. | `any` | `null` | no |
| <a name="input_service_control_policies"></a> [service\_control\_policies](#input\_service\_control\_policies) | List of SCP Names that are directly applied to this AWS Account. Policies must be created before they can be referenced. | `list(string)` | `[]` | no |
| <a name="input_warning_threshold_percentage"></a> [warning\_threshold\_percentage](#input\_warning\_threshold\_percentage) | An Alert is sent when the actual costs this this percentage threshold | `number` | `85` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | n/a |
