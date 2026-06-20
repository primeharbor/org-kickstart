# org-kickstart

Kickstart and manage your AWS Organization via Terraform via PrimeHarbor's opinionated version of Control Tower

**Full documentation, setup, and bootstrap instructions are at [aws-kickstart.org](https://aws-kickstart.org).** This README only covers day-to-day operation of an existing deployment.

(Note for whomever is first setting this up - replace example with your environment name, and other settings.)


## Setting up Granted
Granted configs are now available via org-kickstart repo.

```
granted registry add -n example-admin -u git@github.com:example/example-org-kickstart.git
```

## Updating the Org

1. Make the changes to example.tfvars
2. Make sure you've got credentials to the example-payer
  `export AWS_DEFAULT_PROFILE=example-payer`
3. Setup the repo
  `make env=example tf-init`
4. Run the plan
  `make env=example tf-plan`
5. Run the Apply
  `make env=example tf-apply`
6. If new accounts were added, update granted configs
  `make env=example granted`
7. Commit the changes


## Checking the org-kickstart version

The version / location of the module is in `main.tf`

```hcl
  # Use the latest
  # source = "github.com/primeharbor/org-kickstart"

  # Pin to a specific release
  # source = "github.com/primeharbor/org-kickstart?ref=0.3.0"
```
