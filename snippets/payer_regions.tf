provider "aws" {
  alias  = "payer-REGION"
  region = "REGION"
  default_tags {
    tags = local.default_tags
  }
}
