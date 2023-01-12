resource "aws_cloudwatch_log_group" "containers" {
  name              = "/aws/ecs/${var.service_name}"
  retention_in_days = 7
  tags              = var.tags
}

data "aws_iam_policy_document" "cloudwatch_logs_policy" {
  count = var.task_role_arn == "" ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = [aws_cloudwatch_log_group.containers.arn]
  }
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  count = var.task_role_arn == "" ? 1 : 0

  name   = "cw-logs-access-${var.service_name}-${data.aws_region.current.name}"
  path   = "/ecs/task-role/"
  policy = data.aws_iam_policy_document.cloudwatch_logs_policy[0].json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy" {
  count = var.task_role_arn == "" ? 1 : 0

  role       = aws_iam_role.ecs_task_role[0].name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy[0].arn
}
