data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data aws_ecr_repository "repo" {
  name = var.service_name
}
