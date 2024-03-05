locals {
  // optional FluentBit container for log aggregation
  fluentbit_container_defaults = {
    name                   = var.firelens.container_name
    image                  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecr-public/aws-observability/aws-for-fluent-bit:init-2.32.0.20240122"
    essential              = true
    mountPoints            = []
    portMappings           = []
    readonlyRootFilesystem = false
    user                   = startswith(upper(var.operating_system_family), "WINDOWS") ? null : "0:1337"
    volumesFrom            = []

    environment = [
      // Valid values are: debug, info and error, default if missing: info
      { name = "FLB_LOG_LEVEL", value = "error" },
      {
        "name" : "aws_fluent_bit_init_s3_1",
        "value" : "arn:aws:s3:::config-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/ecs/fluent-bit/service-custom.conf"
      },
      {
        "name" : "aws_fluent_bit_init_s3_2",
        "value" : "arn:aws:s3:::config-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/ecs/fluent-bit/filters-custom.conf"
      },
      {
        "name" : "aws_fluent_bit_init_s3_3",
        "value" : "arn:aws:s3:::config-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/ecs/fluent-bit/parsers-custom.conf"
      },
    ],

    # https://github.com/aws-samples/amazon-ecs-firelens-examples/tree/mainline/examples/fluent-bit/health-check
    healthCheck = {
      retries = 3
      command = [
        "CMD-SHELL",
        "curl --fail localhost:2020/api/v1/uptime"
      ]
      timeout     = 2
      interval    = 5
      startPeriod = 10
    }


    firelensConfiguration = {
      type    = "fluentbit"
      options = { enable-ecs-log-metadata : "true" }
    }

    logConfiguration = var.cloudwatch_logs.enabled ? {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.containers[0].name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "fluentbit"
        mode                  = "non-blocking"
      }
    } : null
  }

  fluentbit_container = var.firelens.enabled ? jsonencode(module.fluentbit_container_definition.merged) : ""
}

module "fluentbit_container_definition" {
  source  = "registry.terraform.io/cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"

  maps = [
    local.fluentbit_container_defaults,
    var.firelens.container_definition
  ]
}

data "aws_iam_policy_document" "fluent_bit_config_access" {
  count = var.firelens.enabled && var.task_role_arn == "" ? 1 : 0

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:aws:s3:::config-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/ecs/fluent-bit/*",
      "arn:aws:s3:::config-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}",
    ]
  }
}

resource "aws_iam_policy" "fluent_bit_config_access" {
  count = var.firelens.enabled && var.task_role_arn == "" ? 1 : 0

  name   = "fluent-bit-config-access-${var.service_name}-${data.aws_region.current.name}"
  path   = "/ecs/task-role/"
  policy = data.aws_iam_policy_document.fluent_bit_config_access[count.index].json
}

resource "aws_iam_role_policy_attachment" "fluent_bit_config_access" {
  count = var.firelens.enabled && var.task_role_arn == "" ? 1 : 0

  role       = aws_iam_role.ecs_task_role[count.index].name
  policy_arn = aws_iam_policy.fluent_bit_config_access[count.index].arn
}