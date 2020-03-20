# Code Deploy: IAM Role
# https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-service-role.html
resource "aws_iam_role" "code_pipeline_role" {
  count              = var.use_code_deploy ? 1 : 0
  name               = "code_pipeline_role"
  description        = "Provides full access to AWS CodePipeline via the AWS Management Console."
  assume_role_policy = data.aws_iam_policy_document.allow_code_pipeline_role.json
  #  tags               = module.tags.default_tags
}

data "aws_iam_policy_document" "allow_code_pipeline_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "AWSCodePipelineFullAccess" {
  count      = var.use_code_deploy ? 1 : 0
  role       = aws_iam_role.code_pipeline_role[count.index].name
  policy_arn = data.aws_iam_policy.AWSCodePipelineFullAccess.arn
}

data "aws_iam_policy" "AWSCodePipelineFullAccess" {
  arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployFullAccess" {
  count      = var.use_code_deploy ? 1 : 0
  role       = aws_iam_role.code_pipeline_role[count.index].name
  policy_arn = data.aws_iam_policy.AWSCodeDeployFullAccess.arn
}

data "aws_iam_policy" "AWSCodeDeployFullAccess" {
  arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}

resource "aws_iam_policy" "code_pipepline_extra" {
  count       = var.use_code_deploy ? 1 : 0
  name        = "tf-code-pipeline-extras"
  description = "tf-code-pipeline-extras"
  policy      = data.aws_iam_policy_document.code_pipepline_extra.json
}

resource "aws_iam_role_policy_attachment" "code_pipepline_extra" {
  count      = var.use_code_deploy ? 1 : 0
  role       = aws_iam_role.code_pipeline_role[count.index].name
  policy_arn = aws_iam_policy.code_pipepline_extra[count.index].arn
}

data aws_ecr_repository "repo" {
  name = var.service_name
}

data "aws_iam_policy_document" "code_pipepline_extra" {
  statement {
    actions   = ["ecr:DescribeImages"]
    resources = [data.aws_ecr_repository.repo.arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket", "s3:PutObject"]
    resources = [
      aws_s3_bucket.codepipeline_bucket[0].arn,
      "${aws_s3_bucket.codepipeline_bucket[0].arn}/*"
    ]
  }
  statement {
    actions   = ["ecs:RegisterTaskDefinition"]
    resources = ["*"]
  }
}
