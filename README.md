# org-kickstart

Kickstart and manage your AWS Organization via Terraform — PrimeHarbor's opinionated alternative to Control Tower.

📖 **Full documentation, setup, and parameter reference: [aws-kickstart.org](https://aws-kickstart.org)**

## Releases

The default branch is **`latest`** and always holds the most recent changes. Each release is a
**frozen, tagged version** (e.g. `0.3.0`).

- Track the newest code: `source = "github.com/primeharbor/org-kickstart"`
- Pin to a release: `source = "github.com/primeharbor/org-kickstart?ref=0.3.0"`

We target **quarterly releases**, but may cut a new version sooner when significant new AWS
organization-management features warrant it. See the
[Releases](https://aws-kickstart.org/docs/releases/) page.

## Why?

Control Tower sucks. It's a massive beast designed to support highly regulated companies with a cloud compliance framework that's more than what most companies need. Control Tower is hard to adjust, missing some key features, and lags behind AWS Best practices (it took a long time for Organization CloudTrail and GuardDuty Delegated Admin to be supported). You need a PhD in AWS Service Catalog to modify anything. It heavily leverages AWS Config, making it very expensive for small orgs.

Most orgs implement Control Tower because their AWS SA was told to tell them to, or because they needed some form of "account factory", and you can easily click a button to fully provision an account.

The Org Kickstart is intended to be a landing zone for the rest of us. Deployed in a brand new AWS account (after a [few Artisanal steps](BOOTSTRAP.md) are completed), it will deploy the good parts of ControlTower/Landing Zones with out all the expensive cruft.

## What it does

org-kickstart is indented to support all the basic things needed to setup a properly governed and secure AWS organization from scratch. It will:

1. Create a Security Account (required)
    1. Delegate access for GuardDuty, Macie, Inspector, Security Hub, SSO, and CloudFormation to the Security Account
    2. Configure GuardDuty, Macie, Inspector, Security Hub in every default region for all accounts.
2. Create a CloudTrail bucket in the Security Account, and enable an Organizations CloudTrail in the Management (Payer) Account
3. Set the alternate contacts for Billing, Operations, and Security for all AWS accounts.
4. Create four default Organizational Units (OUs), along with any custom OUs defined in tfvars:
    1. Workloads (required)
    2. Governance (required)
    3. Sandbox (required)
    4. Suspended (required)
5. Create a default AI Opt-out policy and apply it to the root OU (required)
6. Manage the AWS Account and OU placement
6. Create a CloudFormation Delegated Admin StackSet to deploy an Audit Role in all accounts that trusts the Security Account
7. Create an S3 Bucket for Billing Reports and an Athena compatible CUR report on a customizable frequency
8. Enable all the important Organization Integrated Services: (required)
    1. IAM Access Analyzer
    2. AWS Account Portal
    3. AWS Backup
    4. CloudTrail
    5. AWS Config
    6. Firewall Manager
    7. GuardDuty & GuardDuty Malware Protection
    8. Personal Health Dashboard
    9. AWS Inspector (v2)
    10. License Manager
    11. Macie (v2)
    12. CloudFormation StackSets
    13. Resource Access Manager
    14. Trusted Advisor
    15. Security Hub
    16. SSM
    17. AWS IAM Identity Center (SSO)
9. Manage Service Control Policies, Declarative Policies, and Resource Control Policies and allow templating of RCPs/SCPs/DPs
10. Grant Admin Access to all accounts via AWS Identity Center
    1. Create a AdministratorAccess AWS Identity Center PermissionSet
    2. Create a Identity Center Group
    3. Assign the PermissionSet and Group to every account

While this is intended to be the "highly opinionated" solution "for the rest of us", many options are configurable or can be disabled. Only the items above marked "required" cannot be disabled.


## Setup

You will need to create the new AWS account and enable IAM Identity Center (SSO) by hand before
using org-kickstart — see [BOOTSTRAP.md](BOOTSTRAP.md) (or the
[Bootstrap guide](https://aws-kickstart.org/docs/getting-started/bootstrap/)).

Then copy [`examples/local-deploy`](examples/local-deploy) into your own private repo to manage your
organization. The complete walkthrough — repo setup, an annotated tfvars example, and the full
parameter reference — lives on **[aws-kickstart.org](https://aws-kickstart.org/docs/getting-started/)**.

## Using with an existing org

org-kickstart can adopt an existing organization. See [IMPORTING.md](IMPORTING.md) and the
[Importing guide](https://aws-kickstart.org/docs/getting-started/importing/). Note that org import
is **experimental and incomplete** — review the plan closely to confirm what is imported versus
created. A number of features can be disabled when adopting a more complex org (e.g.
`cloudtrail_bucket_name = null`, `disable_sso_management = true`, `deploy_audit_role = false`).

## Prior Art

* https://github.com/george-richardson/terraform-aws-personal-org
* https://github.com/chris-qa-org/terraform-aws-organzation-and-sso/tree/main/examples/accounts-and-permission-assignments
