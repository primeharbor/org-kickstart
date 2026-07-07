# New Features

## Security Hub 2.0 Support (`security_hub_configuration`)

A new optional `security_hub_configuration` block enables Security Hub 2.0 org-wide.
When the block is absent, no action is taken.

```hcl
  security_hub_configuration = {
    enable_security_hub_2                = true
    enable_security_hub_for_all_accounts = true
    enable_inspector_for_all_accounts    = true
    create_cost_estimation_role  = true
    create_org_delegation_policy = true
    aggregation_region           = "us-east-1"
    enable_threat_detection      = true
    threat_detection_features = {
      enable_ebs_malware_scanning = true
      enable_eks_protection       = true
      enable_s3_protection        = true
      enable_lambda_protection    = true
      enable_rds_protection       = true
      enable_runtime_monitoring   = true
    }

  }
```

`create_cost_estimation_role` and `create_org_delegation_policy` default to `true` when the
block is present but the field is omitted. `enable_security_hub_2` and
`enable_threat_detection` both default to `false` — you must explicitly opt in.

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

### `enable_threat_detection` (GuardDuty)

**Default changed to `false`** — previously defaulted to `true` when the block was
present, but the flag now has real behavior instead of being reserved, so absent-in-tfvars
must mean "not enabled." Set to `true` explicitly to opt in.

When `true`, Org Kickstart creates in every enabled region (via `for_each`):

- `aws_guardduty_detector.security_account[<region>]` — the delegated admin's detector
- `aws_guardduty_organization_admin_account.security_account[<region>]` — designates the
  security account as the GuardDuty delegated admin
- `aws_guardduty_organization_configuration.security_account[<region>]` — sets
  `auto_enable_organization_members = "ALL"` so every FUTURE org account gets a detector
  automatically (see the enrollment caveat below for existing accounts).

The Security Hub 2.0 console's "deployment" action does not turn on auto-enroll for
future accounts (it explicitly says so in the console UI); the Terraform-managed org
config does.

**Extended features** — `threat_detection_features` sub-object with per-feature enable
flags. Each `enable_*` = `true` creates one `aws_guardduty_organization_configuration_feature`
resource per enabled region with `auto_enable = "ALL"`:

- `enable_ebs_malware_scanning` → `EBS_MALWARE_PROTECTION`
- `enable_eks_protection` → `EKS_AUDIT_LOGS`
- `enable_s3_protection` → `S3_DATA_EVENTS`
- `enable_lambda_protection` → `LAMBDA_NETWORK_LOGS`
- `enable_rds_protection` → `RDS_LOGIN_EVENTS`
- `enable_runtime_monitoring` → `RUNTIME_MONITORING`
- `enable_eks_runtime_monitoring` → `EKS_RUNTIME_MONITORING` (legacy, being deprecated)
- `enable_ai_analyst` → `AI_ANALYST` (preview)

All fields default to `false`.

**Caveat — existing accounts don't auto-enroll.** `auto_enable_organization_members = "ALL"`
in `aws_guardduty_organization_configuration` reads like it will enroll every existing
org account plus every future one. Empirically it only fires for future accounts.
Existing accounts that were never members (or were disassociated via `DeleteMembers` —
including the ones cleaned up by `wipe_sechub_v2.py` / `wipe_sechub_cspm.py`) stay as
"Not a member" in the console. The fix is a one-shot `CreateMembers` call from the
delegated admin for each existing account in each region.

Ship the fix as a helper script rather than Terraform resources — per-account-per-region
`aws_guardduty_member` resources don't scale to orgs with hundreds of accounts:

**`examples/local-deploy/scripts/enable_existing_guardduty_accounts.sh`** (new). Bash
one-shot that discovers the GD delegated admin from the payer, assumes
`OrganizationAccountAccessRole` into it, and calls `CreateMembers` in every enabled
region with the full non-admin account list (batched in groups of 50). Safe to re-run;
already-enrolled accounts come back in `UnprocessedAccounts` as warnings. Run once per
fresh setup or wipe-and-restore. Once every account has been enrolled the first time,
`auto_enable_organization_members = "ALL"` handles future accounts automatically.

**Note:** `modules/security_services/guardduty.tf` still exists but should be considered
deprecated. It was a pre-provider-6 workaround for multi-region resources that the AWS
provider now handles natively via the `region` argument.

**Constraint:** `enable_threat_detection = true` requires `security_services.disable_guardduty = true`
(or the `security_services` block to be absent). A variable validation enforces this at
plan time — otherwise both `modules/security_services/guardduty.tf` and the new
resources in `security_hub_2.tf` would try to manage GuardDuty simultaneously and fight
each other on every apply.

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
