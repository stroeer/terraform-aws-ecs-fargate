data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_role" "code_build" {
  count = var.code_build_role != "" ? 1 : 0
  name  = var.code_build_role
}

data "aws_iam_role" "code_pipeline" {
  count = var.code_pipeline_role != "" ? 1 : 0
  name  = var.code_pipeline_role
}

locals {
  iam_path            = "/ecs/deployment/"
  artifact_bucket_arn = var.artifact_bucket == "" ? module.s3_bucket.s3_bucket_arn : data.aws_s3_bucket.codepipeline[0].arn
}
