provider "aws" {
  alias  = "security-account-REGION"
  region = "REGION"
  assume_role {
    role_arn = "arn:aws:iam::${module.organization.security_account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags {
    tags = local.default_tags
  }
}
