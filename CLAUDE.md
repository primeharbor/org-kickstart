# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

org-kickstart is a Terraform module for bootstrapping and managing AWS Organizations. It's an opinionated alternative to AWS Control Tower, focusing on essential security and governance features without the complexity and cost. It manages organization structure, security services (GuardDuty, Macie, SecurityHub, Inspector), CloudTrail, AWS Identity Center (SSO), Service Control Policies (SCPs), Resource Control Policies (RCPs), Declarative Policies, and more.

## Architecture

### Core Components

**Management/Payer Account**: The root AWS organization account where org-kickstart is deployed. Manages the organization structure, OUs, and organization-wide settings.

**Security Account**: Special delegated account that holds the CloudTrail bucket, is trusted by all accounts for security-audit role, and serves as delegated administrator for security services (GuardDuty, Macie, SecurityHub, Inspector, SSO, CloudFormation StackSets).

**Four Required OUs**:
- `Governance` - Security and payer accounts
- `Workloads` - Most production accounts
- `Sandbox` - Development accounts with more service freedom
- `Suspended` - Accounts pending closure

### Multi-Provider Architecture

Terraform doesn't handle multi-region well. This module uses pre-defined AWS providers for all default (non-opt-in) regions for both payer and security accounts to enable regional security services. The `scripts/generate_regionblocks.sh` script generates provider configurations dynamically.

**Important**: When adding regional resources, you must:
1. Add provider blocks for each region in both payer and security accounts
2. Use the `generate_regionblocks.sh` script to regenerate provider configurations
3. Run `terraform init` after generating new region blocks

### Module Structure

- `modules/account/` - Manages individual AWS accounts with budgets, contacts, SSO assignments
- `modules/org_policies/` - Generic module for SCPs, RCPs, and Declarative Policies
- `modules/security_services/` - Enables GuardDuty, Macie, SecurityHub, Inspector per region
- `modules/stacksets/` - Deploys CloudFormation StackSets (audit role deployment)
- `modules/billing_alerts/` - SNS-based billing alerts
- `modules/datatrail/` - Advanced CloudTrail with S3 data events

### Key Files

- [main.tf](main.tf) - Provider definitions and data sources
- [organization.tf](organization.tf) - Organization resource and service enablement
- [security_account.tf](security_account.tf) - Security account creation and delegation
- [accounts.tf](accounts.tf) - Module calls for all workload accounts
- [ous.tf](ous.tf) - Organizational unit definitions and OU name-to-ID mapping
- [scps.tf](scps.tf) - Service Control Policies
- [rcps.tf](rcps.tf) - Resource Control Policies
- [declarative_policies.tf](declarative_policies.tf) - EC2 Declarative Policies
- [sso.tf](sso.tf) - AWS Identity Center permission sets and group assignments
- [cloudtrail.tf](cloudtrail.tf) - Organization CloudTrail configuration
- [billing.tf](billing.tf) - CUR reports and billing data bucket
- [audit-role.tf](audit-role.tf) - StackSet for deploying audit role to all accounts

## Terraform Workflow

### Initial Setup for New Organization

See [examples/local-deploy/README.md](examples/local-deploy/README.md) for detailed first-time setup. Key steps:

1. Enable AWS Organizations and SSO manually in console (see BOOTSTRAP.md)
2. Create terraform state bucket and set up backend
3. Run `terraform init`
4. Import organization and payer account using provided scripts
5. Create security account first with targeted apply: `terraform apply -target module.security_account`
6. Disable accounts and SCPs in tfvars for first apply
7. Run `scripts/generate_regionblocks.sh` to create multi-region provider blocks
8. Re-run `terraform init` after generating region blocks
9. Enable additional features incrementally

### Importing Existing Organizations

See [IMPORTING.md](IMPORTING.md) for complete import guidance. The `scripts/import_org.sh` script generates import blocks and tfvars entries for existing resources.

**Important Resources to Import**:
- Organization: `aws_organizations_organization.org`
- Payer account: `aws_organizations_account.payer`
- Security account: `module.security_account.aws_organizations_account.account`
- Existing OUs, SCPs, CloudTrail, SSO resources

### Standard Commands

```bash
# Initialize (run after backend changes or new provider configs)
terraform init -backend-config="<env>.tfbackend"

# Plan changes
terraform plan -var-file="<env>.tfvars" -out=<env>-terraform.tfplan

# Apply changes
terraform apply <env>-terraform.tfplan

# Targeted operations (use sparingly)
terraform plan -var-file="<env>.tfvars" -target <resource>
terraform apply -var-file="<env>.tfvars" -target <resource>

# Show planned changes
terraform show <env>-terraform.tfplan

# Import existing resource
terraform import -var-file="<env>.tfvars" <resource_address> <resource_id>
```

### Common Development Scenarios

**Adding a new AWS account**: Add entry to `accounts` map in tfvars. The account module handles creation, OU assignment, SSO, budgets, and contacts.

**Creating new SCP/RCP/Declarative Policy**:
1. Add policy JSON file (or template with `.tftpl` extension) to `policies/` directory
2. Add policy definition to `service_control_policies`, `resource_control_policies`, or `declarative_policies` map in tfvars
3. Specify `policy_targets` as list of OU names or IDs

**Policy Templating**: Policy files with `.tftpl` extension support Terraform templating. Use `policy_vars` map in policy definition to pass variables. Example: `${audit_role_name}`, `${org_id}`, `${allowed_regions}`.

**Adding custom OU**: Add to `organization_units` map in tfvars. Specify `parent_id` to create nested OUs (use OU name from existing OUs).

**Managing account contacts**: Use `global_billing_contact`, `global_security_contact`, `global_operations_contact`, and `global_primary_contact` for organization-wide defaults. Override per-account in account definition.

**Adding a new top-level variable / feature**: When introducing a new variable in [variables.tf](variables.tf) that callers should be able to set via tfvars, also wire it through [examples/local-deploy/main.tf](examples/local-deploy/main.tf). Callers consume this module by passing a single `organization` object, so each variable must be re-exposed in the example module block with a `lookup(var.organization, "<var_name>", <default>)` pass-through. Skipping this step means callers can put the value in their tfvars but it will be silently ignored. Also update [examples/local-deploy/sample.tfvars](examples/local-deploy/sample.tfvars) so the feature is discoverable.

  **Keep the site docs in sync** (the docs live in the `org-kickstart-site` repo, published at https://aws-kickstart.org). For every variable added, changed, or removed in [variables.tf](variables.tf):
  - Update the **parameter reference** at `content/en/docs/reference/parameter-reference.md` — add/edit the row (or block, for object-typed variables) in the matching section, with the correct type, default, and description. The parameter reference is hand-maintained, so it does not update itself; treat a missing/stale entry the same as a missing release note.
  - Regenerate the **module documentation** at `content/en/docs/reference/module-docs/_index.md` by running `make generate-module-docs` in the `org-kickstart-site` repo (it runs `terraform-docs` against the module source). This page is auto-generated — do not hand-edit it.
  - Significant features should also get their own page or section under `content/en/docs/` (see the Granted Support and Account Configurator pages as examples).

## Important Conventions

### Release Notes (do this on every commit)

Every change MUST be recorded in the release-notes file for the version it targets:
`docs/v<MAJOR>.<MINOR>.<PATCH>-notes.md` (e.g. [docs/v0.3.0-notes.md](docs/v0.3.0-notes.md)). When
preparing a commit, add a bullet to the appropriate section of that file describing the change:

- **New Features** — new variables, resources, or capabilities
- **Major / Minor Breaking Change** — anything requiring a `terraform state mv`, recreation, or a
  tfvars change to keep working (include the migration steps)
- **Minor Updates** — small enhancements, dependency bumps, lint/Checkov fixes
- **Bug Fixes** — corrected behavior (e.g. `depends_on` ordering, validation fixes)
- **Known Bugs** — anything still broken that users should be aware of

If the target version doesn't have a notes file yet, create it. Treat a missing release-notes entry
the same as a missing test: the change isn't done until it's documented.

### Partition Awareness

The code uses `data.aws_partition.current.partition` to support commercial, GovCloud, and other AWS partitions. When constructing ARNs, always use: `arn:${data.aws_partition.current.partition}:service:...`

Never hard-code `arn:aws:` - this breaks in non-commercial partitions.

### OU Targeting

Policies can target OUs by name or ID. The `local.ou_name_to_id` map (defined in [ous.tf](ous.tf)) enables name-based lookups. Use "Root" to target the root OU.

### Required vs Optional Features

**Cannot be disabled**:
- Security Account
- Four default OUs (Governance, Workloads, Sandbox, Suspended)
- AI opt-out policy
- Core organization integrated services

**Can be disabled via variables**:
- CloudTrail management: Set `cloudtrail_bucket_name = null`
- SSO management: Set `disable_sso_management = true`
- Audit role StackSet: Set `deploy_audit_role = false`
- Security services: Use `security_services` object with `disable_*` flags
- CUR reports: Set `cur_report_frequency = "NONE"`
- Alternate contacts: Omit contact blocks from tfvars

### Account Module Usage

The account module is instantiated for each account in the `accounts` variable. The security account uses the same module but is handled specially. Each account module manages:
- AWS Organizations account resource
- Parent OU assignment (via `parent_ou_name` or `parent_ou_id`)
- SSO group assignment
- AWS Budgets
- Alternate contacts (billing, operations, security)
- Primary contact
- Policy attachments (SCPs, RCPs, Declarative Policies)
- Delegated administrator enablement

## Debugging Tips

**Error: "You don't have permissions to access this resource" when listing accounts**: The Security Account must have delegated admin enabled before security services can be planned. Delete generated security service files, apply to create security account delegation, then regenerate.

**Resource import failures**: If importing a resource that doesn't exist (typically delegated_administrator), the error can be ignored - org-kickstart will create it.

**Policy attachment issues**: Ensure OUs exist before attaching policies. Use `depends_on` if creating both OU and policy in same apply.

**Multi-region provider errors**: After adding new regional resources, always run `generate_regionblocks.sh` and `terraform init`.

## Testing

When modifying this module, test changes by:
1. Creating a test tfvars file with minimal configuration
2. Using `terraform plan` extensively before apply
3. Testing in non-production organization first
4. Using targeted applies for risky changes
5. Verifying SCPs don't lock out root or prevent remediation

For SCP testing specifically: Always ensure audit role and break-glass access patterns are excluded from restrictions.
