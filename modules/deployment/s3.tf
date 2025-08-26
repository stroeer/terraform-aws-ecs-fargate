module "s3_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "5.6.0"
  create_bucket = var.artifact_bucket == "" ? true : false

  bucket        = "codepipeline-bucket-${var.service_name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
  force_destroy = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true
  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = var.artifact_bucket_server_side_encryption

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })
}

data "aws_s3_bucket" "codepipeline" {
  count  = var.artifact_bucket != "" ? 1 : 0
  bucket = var.artifact_bucket
}
