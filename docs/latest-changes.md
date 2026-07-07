# New Features

## Security Hub 2.0 Support (`security_hub_configuration`)

A new optional `security_hub_configuration` block enables Security Hub 2.0 org-wide.
When the block is absent, no action is taken.

```hcl
security_hub_configuration = {
  enable_security_hub_2                = true
  enable_security_hub_for_all_accounts = true
  enable_inspector_for_all_accounts    = true
  create_cost_estimation_role          = true
  create_org_delegation_policy         = true
  enable_threat_detection              = true
  aggregation_region                   = "us-east-1"
}
```

`create_cost_estimation_role`, `create_org_delegation_policy`, and `enable_threat_detection`
default to `true` when the block is present but the field is omitted. `enable_security_hub_2`
defaults to `false`.

`enable_security_hub_for_all_accounts` and `enable_inspector_for_all_accounts` are
**tri-state** (`true` / `false` / absent). The `SECURITYHUB_POLICY` and `INSPECTOR_POLICY`
org policies are one-shot — detaching an *enable* policy does not disable the service; you
have to attach a *disable* policy to reverse it. Org Kickstart therefore always creates
both the enable and disable policies whenever `security_hub_configuration` is present, and
uses the flag value to decide which one to attach at Root:

- `true` → attach the enable policy at Root
- `false` → attach the disable policy at Root (actively turns the service off org-wide)
- absent → attach neither (Org Kickstart is not managing the Root attachment)

**Constraint:** `enable_security_hub_for_all_accounts = true` requires `enable_security_hub_2 = true`.
A validation on the variable enforces this at plan time — attaching the SECURITYHUB_POLICY at
Root needs the delegated admin and per-region v2 hubs to be up first.

### `create_cost_estimation_role`

Creates `AwsSecurityHubCostEstimatorCrossAccountRole` in the management (payer) account.
This IAM role allows the `AWSServiceRoleForSecurityHub` role in the delegated admin (security)
account to call `ce:GetCostAndUsage` for org-wide cost estimation in the Security Hub 2.0 console.
See [AWS docs](https://docs.aws.amazon.com/securityhub/latest/userguide/setting-up-cross-account-access.html).

### `create_org_delegation_policy`

Creates an AWS Organizations resource policy that grants the security account permission to
read and manage Security Hub policies in the organization. The statements in
`local.org_delegation_statements` in `security_hub_2.tf` are designed to be extended with
additional services as they require org-level delegation.

### `enable_security_hub_2`

When true:

- Creates `aws_securityhub_organization_admin_account` to designate the security account as
  the Security Hub 2.0 delegated administrator (skipped when Security Hub v1 is also enabled,
  since v1 already owns that delegation). Single-region — AWS auto-propagates the admin
  designation to every linked region via central configuration.
- Enables `aws_securityhub_account_v2` in the security account **for every enabled region**
  (via `for_each` over `data.aws_regions.available.names`), so Terraform state matches AWS
  reality when the SECURITYHUB_POLICY at Root propagates enablement org-wide.
- Enables `aws_securityhub_account_v2` in the payer account (single-region).
- All four root-level policy attachments (`securityhub_enable_root`,
  `securityhub_disable_root`, `inspector_enable_root`, `inspector_disable_root`) have
  `depends_on` guards that wait for the entire SH v2 foundation to exist before the
  attachment fires. The foundation is: every `aws_securityhub_account_v2`, the org
  admin registration, the aggregator, the org delegation resource policy, and the cost
  estimator role. Without these guards, the moment the SECURITYHUB_POLICY /
  INSPECTOR_POLICY lands at Root, AWS starts propagating it — any concurrent
  `EnableSecurityHubV2` call that loses the race is blocked with `AccessDeniedException:
  Account is part of an AWS Organization and is being managed by a Security Hub policy`.
- `securityhub_enable_root` and `inspector_enable_root` also depend on the corresponding
  `*_disable_account` opt-out attachments, so per-account opt-outs are always applied
  BEFORE the root enable policy propagates. This avoids briefly enabling a service on an
  opt-out account between the root-enable and the child-disable attachments landing.
- Creates `aws_securityhub_aggregator_v2` in the security account using `SPECIFIED_REGIONS`
  mode to aggregate findings from all enabled regions.

### `enable_security_hub_for_all_accounts`

Controls which `SECURITYHUB_POLICY` (if any) is attached to the Root OU. `true` attaches
`EnableSecurityHubV2` (Security Hub 2.0 + network scanning enabled in all current and
future regions for every account, including newly created ones). `false` attaches
`DisableSecurityHubV2`. Absent leaves the Root attachment unmanaged.

### `enable_inspector_for_all_accounts`

Controls which `INSPECTOR_POLICY` (if any) is attached to the Root OU. `true` attaches
`EnableInspector` (Lambda standard, Lambda code, EC2, ECR, and code repository scanning
enabled in all current and future regions). `false` attaches `DisableInspector`. Absent
leaves the Root attachment unmanaged.

### Per-account opt-outs (`security_hubv2_optout`, `inspector_optout`)

Individual accounts can be explicitly opted out by setting `security_hubv2_optout = true`
or `inspector_optout = true` in their account definition (both default to `false`). When
`true`, the pre-created disable policy is attached directly to that account. When `false`
or omitted, Org Kickstart does nothing for that account and inheritance from the Root
attachment (if any) takes its course.

The direct attachment fires regardless of what is attached at Root, so a single account can
be disabled even when Root has no `enable_security_hub_for_all_accounts` /
`enable_inspector_for_all_accounts` flag set. There is currently no symmetric per-account
opt-in.

```hcl
accounts = {
  dev = {
    account_name          = "my-dev"
    account_email         = "aws+dev@example.com"
    parent_ou_name        = "Workloads"
    monthly_budget_amount = 5
    security_hubv2_optout = true   # attach DisableSecurityHubV2 to this account
  }
}
```

## Major Breaking Change


## Minor Updates

- AWS provider minimum version bumped to `>= 6.45.0` (required for `aws_securityhub_account_v2`
  and `aws_securityhub_aggregator_v2`).
- `state_bucket.tf`: added `lifecycle { ignore_changes = [rule] }` to the SSE configuration
  resource to suppress perpetual drift from AWS-injected `blocked_encryption_types` and
  `bucket_key_enabled` fields.

## Minor Breaking Change


## Bug Fixes
* adding md5/etag checksum to the account_configurator config yaml to force terraform update when the file changes
* alter DenyRootSCP.json to permit `iam:GetAccountSummary`, which is required to see if root credentials are present.

## Known Bugs
