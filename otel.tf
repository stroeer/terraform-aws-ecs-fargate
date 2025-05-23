locals {
  // optional AWS Distro for OpenTelemetry container
  otel_container_defaults = {
    essential              = false
    image                  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecr-public/aws-observability/aws-otel-collector:v0.42.0"
    name                   = "otel"
    readonlyRootFilesystem = false
    mountPoints            = []
    portMappings           = []
    systemControls         = []
    ulimits                = []
    user                   = startswith(upper(var.operating_system_family), "WINDOWS") ? null : "0:1337"
    volumesFrom            = []

    logConfiguration = var.cloudwatch_logs.enabled ? {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.cloudwatch_logs.name == "" ? aws_cloudwatch_log_group.containers[0].name : var.cloudwatch_logs.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "otel"
        mode                  = "non-blocking"
      }
    } : null
  }
  otel_container = var.otel.enabled ? jsonencode(module.otel_container_definition.merged) : ""
}

module "otel_container_definition" {
  source  = "registry.terraform.io/cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"

  maps = [
    local.otel_container_defaults,
    var.otel.container_definition
  ]
}

resource "aws_iam_role_policy_attachment" "otel" {
  count = var.otel.enabled && var.task_role_arn == "" ? 1 : 0

  policy_arn = aws_iam_policy.otel[count.index].arn
  role       = aws_iam_role.ecs_task_role[count.index].name
}

resource "aws_iam_policy" "otel" {
  count = var.otel.enabled && var.task_role_arn == "" ? 1 : 0

  name   = "${var.service_name}-otel-${data.aws_region.current.name}"
  policy = data.aws_iam_policy_document.otel[count.index].json
}

data "aws_iam_policy_document" "otel" {
  count = var.otel.enabled && var.task_role_arn == "" ? 1 : 0

  statement {
    sid = "AWSDistroOpenTelemetryPolicy"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "xray:GetSamplingRules",
      "xray:GetSamplingStatisticSummaries",
      "xray:GetSamplingTargets",
      "xray:PutTelemetryRecords",
      "xray:PutTraceSegments"
    ]
    resources = ["*"]
  }
}
