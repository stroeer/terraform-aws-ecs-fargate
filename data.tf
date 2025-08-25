data "aws_region" "current" {
  region = var.region
}

data "aws_caller_identity" "current" {}
