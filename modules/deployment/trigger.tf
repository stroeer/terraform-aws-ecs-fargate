moved {
  from = aws_cloudwatch_event_rule.this
  to   = aws_cloudwatch_event_rule.ecr-action
}

resource "aws_cloudwatch_event_rule" "ecr-action" {
  name        = "${var.service_name}-ecr-trigger"
  description = "Capture ECR push and replication events."

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })

  event_pattern = <<HEREDOC
{
    "detail-type": [
        "ECR Image Action", "ECR Replication Action"
    ],
    "source": [
        "aws.ecr"
    ],
    "detail": {
        "action-type": [
            "REPLICATE", "PUSH"
        ],
        "image-tag": [
            "${var.ecr_image_tag}"
        ],
        "repository-name": [
            "${var.ecr_repository_name}"
        ],
        "result": [
            "SUCCESS"
        ]
    }
}
HEREDOC
}

resource "aws_cloudwatch_event_target" "trigger" {
  rule      = aws_cloudwatch_event_rule.ecr-action.name
  target_id = "CodePipeline"
  arn       = aws_codepipeline.codepipeline.arn
  role_arn  = aws_iam_role.trigger.arn
}

resource "aws_iam_role" "trigger" {
  name               = "${var.service_name}-${data.aws_region.current.region}-ecr-trigger"
  path               = "/ecs/deployment/"
  assume_role_policy = data.aws_iam_policy_document.trigger-assume-role-policy.json

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })
}

data "aws_iam_policy_document" "trigger-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "trigger" {
  name   = "${var.service_name}-${data.aws_region.current.region}-ecr-trigger"
  path   = "/ecs/deployment/"
  policy = data.aws_iam_policy_document.trigger-permissions.json
}

data "aws_iam_policy_document" "trigger-permissions" {
  statement {
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.codepipeline.arn]
  }
}

resource "aws_iam_role_policy_attachment" "trigger" {
  policy_arn = aws_iam_policy.trigger.arn
  role       = aws_iam_role.trigger.name
}
