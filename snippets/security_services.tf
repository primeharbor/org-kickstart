module "security-services-REGION" {
  source = "./modules/security_services"
  providers = {
    aws.security_account = aws.security-account-REGION
    aws.payer_account    = aws.payer-REGION
  }
  security_account_id = module.security_account.account_id
  disable_guardduty   = local.security_services["disable_guardduty"]
  disable_macie       = local.security_services["disable_macie"]
  disable_inspector   = local.security_services["disable_inspector"]
  disable_securityhub = local.security_services["disable_securityhub"]
}
