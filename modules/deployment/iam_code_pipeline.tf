locals {
  create_code_pipeline_iam = var.enabled && var.code_pipeline_role == ""
}

resource "aws_iam_role" "code_pipeline_role" {
  count              = local.create_code_pipeline_iam ? 1 : 0
  name               = "code-pipeline-${var.service_name}"
  path               = local.iam_path
  assume_role_policy = data.aws_iam_policy_document.allow_code_pipeline_assume[count.index].json

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })
}

data "aws_iam_policy_document" "allow_code_pipeline_assume" {
  count = local.create_code_pipeline_iam ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "code_pipeline" {
  count  = local.create_code_pipeline_iam ? 1 : 0
  name   = "deployment-pipeline-${var.service_name}"
  path   = local.iam_path
  policy = data.aws_iam_policy_document.code_pipepline_permissions[count.index].json
}

resource "aws_iam_role_policy_attachment" "code_pipepline_extra" {
  count      = local.create_code_pipeline_iam ? 1 : 0
  role       = aws_iam_role.code_pipeline_role[count.index].name
  policy_arn = aws_iam_policy.code_pipeline[count.index].arn
}

data "aws_iam_policy_document" "code_pipepline_permissions" {
  count = local.create_code_pipeline_iam ? 1 : 0

  statement {
    actions = ["ecr:DescribeImages"]

    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      local.artifact_bucket_arn,
      "${local.artifact_bucket_arn}/*"
    ]
  }

  statement {
    # start downstream builds and retrieve output artefacts
    actions = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]

    resources = [aws_codebuild_project.this[count.index].arn]
  }

  statement {
    actions = [
      # cloudtrail reports that codepipeline actually requires access to `*`
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:UpdateService"
    ]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.cluster_name}/${var.service_name}"]
  }
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS" {
  count      = local.create_code_pipeline_iam ? 1 : 0
  role       = aws_iam_role.code_pipeline_role[count.index].name
  policy_arn = data.aws_iam_policy.AWSCodeDeployRoleForECS[count.index].arn
}

data "aws_iam_policy" "AWSCodeDeployRoleForECS" {
  count = local.create_code_pipeline_iam ? 1 : 0
  arn   = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}