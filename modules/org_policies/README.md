# Org-Kickstart - Organizational Policies Module

Copyright 2025 Chris Farris <chris@primeharbor.com>

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
| [aws_organizations_policy.org_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.org_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_do_not_attach"></a> [do\_not\_attach](#input\_do\_not\_attach) | If set, this policy will be created but not attached to the root OU | `bool` | `false` | no |
| <a name="input_ou_name_to_id"></a> [ou\_name\_to\_id](#input\_ou\_name\_to\_id) | map to look up OU IDs by name. | `any` | n/a | yes |
| <a name="input_policy_description"></a> [policy\_description](#input\_policy\_description) | Description of the Organization Policy | `string` | `null` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | Org Policy Body (JSON) | `string` | n/a | yes |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | Name of the Organization Policy to Create | `string` | n/a | yes |
| <a name="input_policy_targets"></a> [policy\_targets](#input\_policy\_targets) | OU to attach Organization Policy to | `list(string)` | `[]` | no |
| <a name="input_policy_type"></a> [policy\_type](#input\_policy\_type) | Type of Organization Policy to create. (RESOURCE\_CONTROL\_POLICY, SERVICE\_CONTROL\_POLICY, DECLARATIVE\_POLICY\_EC2) | `string` | n/a | yes |
| <a name="input_root_ou"></a> [root\_ou](#input\_root\_ou) | ID of the Root OU | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id) | Policy ID of the created Policy |
