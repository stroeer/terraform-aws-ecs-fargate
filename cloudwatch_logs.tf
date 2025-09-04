resource "aws_cloudwatch_log_group" "containers" {
  count = var.cloudwatch_logs.enabled && var.cloudwatch_logs.name == "" ? 1 : 0

  name              = var.cloudwatch_logs.name == "" ? "/aws/ecs/${var.service_name}" : var.cloudwatch_logs.name
  retention_in_days = var.cloudwatch_logs.retention_in_days
  tags              = var.tags
}

data "aws_iam_policy_document" "cloudwatch_logs_policy" {
  count = var.cloudwatch_logs.enabled && var.task_execution_role_arn == "" ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = [aws_cloudwatch_log_group.containers[count.index].arn]
  }
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  count = var.cloudwatch_logs.enabled && var.task_execution_role_arn == "" ? 1 : 0

  name   = "cw-logs-access-${var.service_name}-${data.aws_region.current.region}"
  path   = "/ecs/"
  policy = data.aws_iam_policy_document.cloudwatch_logs_policy[count.index].json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy" {
  count = var.cloudwatch_logs.enabled && var.task_execution_role_arn == "" ? 1 : 0

  role       = aws_iam_role.task_execution_role[count.index].name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy[count.index].arn
}
