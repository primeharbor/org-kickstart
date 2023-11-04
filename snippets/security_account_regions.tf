provider "aws" {
  alias  = "security-account-REGION"
  region = "REGION"
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
}
