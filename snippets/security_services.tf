module "security-services-REGION" {
  source = "github.com/primeharbor/org-kickstart/modules/security_services"
  providers = {
    aws.security_account = aws.security-account-REGION
    aws.payer_account    = aws.payer-REGION
  }
  security_account_id = module.organization.security_account_id
  security_services   = var.organization["security_services"]
}