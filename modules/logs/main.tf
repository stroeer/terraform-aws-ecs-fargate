locals {
  index_name = "${var.service_name}-app"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# see https://docs.aws.amazon.com/firehose/latest/dev/controlling-access.html#using-iam-es
data "aws_iam_policy_document" "stream_policy" {
  count = var.enabled ? 1 : 0

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${module.s3_firehose.this_s3_bucket_id}",
      "arn:aws:s3:::${module.s3_firehose.this_s3_bucket_id}/*"
    ]
  }

  statement {
    actions = [
      "es:DescribeElasticsearchDomain",
      "es:DescribeElasticsearchDomains",
      "es:DescribeElasticsearchDomainConfig",
      "es:ESHttpPost",
      "es:ESHttpPut"

    ]
    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}",
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*"
    ]
  }

  statement {
    actions = [
      "es:ESHttpGet"
    ]

    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/_all/_settings",
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/_cluster/stats",
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/${local.index_name}*/_mapping/type-name",
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/_nodes",
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/_nodes/stats",
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/_nodes/*/stats",
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/_stats",
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/${local.index_name}*/_stats"
    ]
  }
}

data "aws_iam_policy_document" "firehose_policy" {
  count = var.enabled ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  count              = var.enabled ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.firehose_policy[count.index].json
  description        = "IAM permissions for ${var.service_name} as Firehose delivery stream to Elasticsearch."
  name               = "firehose_elasticsearch_role_${var.service_name}"
  path               = "/ecs/logging/"

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })
}


resource "aws_iam_policy" "stream_policy" {
  count  = var.enabled ? 1 : 0
  policy = data.aws_iam_policy_document.stream_policy[count.index].json
}

resource "aws_iam_role_policy_attachment" "stream_policy_attachment" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.firehose_role[count.index].name
  policy_arn = aws_iam_policy.stream_policy[count.index].arn
}

module "s3_firehose" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  create_bucket = var.enabled

  bucket        = "failed-documents-${var.service_name}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  acl           = "private"
  force_destroy = true

  versioning = {
    enabled = false
  }

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })
}

data "aws_elasticsearch_domain" "elasticsearch" {
  count       = var.enabled ? 1 : 0
  domain_name = var.domain_name
}

resource "aws_kinesis_firehose_delivery_stream" "elasticsearch_stream" {
  count       = var.enabled ? 1 : 0
  name        = "${var.service_name}-stream"
  destination = "elasticsearch"

  elasticsearch_configuration {
    domain_arn            = data.aws_elasticsearch_domain.elasticsearch[count.index].arn
    index_name            = local.index_name
    index_rotation_period = "OneDay"
    role_arn              = aws_iam_role.firehose_role[count.index].arn
    s3_backup_mode        = "FailedDocumentsOnly"

    cloudwatch_logging_options {
      enabled = false
    }
  }

  s3_configuration {
    bucket_arn         = module.s3_firehose.this_s3_bucket_arn
    compression_format = "GZIP"
    role_arn           = aws_iam_role.firehose_role[count.index].arn
    # kms_key_arn = "todo with default key from data to enable encryption"

    cloudwatch_logging_options {
      enabled = false
    }
  }

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })
}
