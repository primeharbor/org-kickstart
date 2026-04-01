
In tfvars sample
  user_notifications = {
    enabled = false
    contact_email   = "chris@example.com"
    contact_name = "Chris Farris"
    aggregation_duration = "LONG"
  }


  In Variables
  variable "user_notifications" {
  description = "Configuration for user notifications."
  type = object({
    enabled                 = optional(bool, false)
    contact_email           = string
    contact_name            = string
    aggregation_duration    = optional(string, "LONG")
    notification_hub_region = optional(string, "us-east-1")
  })
}

Security Account TF:
```hcl
resource "aws_organizations_delegated_administrator" "health" {
  # count             = var.user_notifications["enabled"] ? 1 : 0
  account_id        = module.security_account.account_id
  service_principal = "health.amazonaws.com"
}
```

