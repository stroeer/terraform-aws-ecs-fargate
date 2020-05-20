resource "aws_cloudwatch_event_rule" "this" {
  count         = var.enabled ? 1 : 0
  name          = "${var.service_name}-ecr-trigger"
  description   = "Capture ECR push events."
  event_pattern = <<PATTERN
{
    "detail-type": [
        "ECR Image Action"
    ],
    "source": [
        "aws.ecr"
    ],
    "detail": {
        "action-type": [
            "PUSH"
        ],
        "image-tag": [
            "production"
        ],
        "repository-name": [
            "${var.ecr_repository_name}"
        ],
        "result": [
            "SUCCESS"
        ]
    }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "trigger" {
  count     = var.enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.this[count.index].name
  target_id = "CodePipeline"
  arn       = aws_codepipeline.codepipeline[count.index].arn
  role_arn  = aws_iam_role.trigger[count.index].arn
}

resource "aws_iam_role" "trigger" {
  count              = var.enabled ? 1 : 0
  name               = "${var.service_name}-${data.aws_region.current.name}-ecr-trigger"
  path               = "/ecs/deployment/"
  assume_role_policy = data.aws_iam_policy_document.trigger-assume-role-policy[count.index].json
}

data "aws_iam_policy_document" "trigger-assume-role-policy" {
  count = var.enabled ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "events.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "trigger" {
  count  = var.enabled ? 1 : 0
  name   = "${var.service_name}-${data.aws_region.current.name}-ecr-trigger"
  path = "/ecs/deployment/"
  policy = data.aws_iam_policy_document.trigger-permissions[count.index].json
}

data "aws_iam_policy_document" "trigger-permissions" {
  count = var.enabled ? 1 : 0
  statement {
    actions   = [
      "codepipeline:StartPipelineExecution"]
    resources = [
      aws_codepipeline.codepipeline[count.index].arn]
  }
}

resource "aws_iam_role_policy_attachment" "trigger" {
  count      = var.enabled ? 1 : 0
  policy_arn = aws_iam_policy.trigger[count.index].arn
  role       = aws_iam_role.trigger[count.index].name
}
