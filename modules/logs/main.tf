data "aws_iam_policy_document" "es_policy" {
  count = var.elasticsearch_domain_arn != "" ? 1 : 0

  statement {
    actions = [
      "es:*"
    ]
    resources = [
      var.elasticsearch_domain_arn,
      "${var.elasticsearch_domain_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "es_policy" {
  count  = var.elasticsearch_domain_arn != "" ? 1 : 0
  path   = "/ecs/task-role/"
  policy = data.aws_iam_policy_document.es_policy[count.index].json
}

resource "aws_iam_role_policy_attachment" "es_policy_attachment" {
  count      = var.elasticsearch_domain_arn != "" ? 1 : 0
  role       = var.task_role_name
  policy_arn = aws_iam_policy.es_policy[count.index].arn
}

resource "aws_cloudwatch_log_group" "fluentbit" {
  count             = var.elasticsearch_domain_arn != "" && var.fluentbit_cloudwatch_log_group_name == "" ? 1 : 0
  name              = "/aws/ecs/${var.service_name}-fluentbit-container"
  retention_in_days = 7

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })
}
