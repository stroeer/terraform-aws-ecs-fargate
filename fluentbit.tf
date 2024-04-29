locals {
  // additional init config files from S3 or files inside a custom image
  // which are added to the FluentBit container as environment variables, see
  // https://github.com/aws/aws-for-fluent-bit/tree/develop/use_cases/init-process-for-fluent-bit
  init_config_files = [
    for idx, file_or_arn in var.firelens.init_config_files : {
      name  = format("aws_fluent_bit_init_%s", idx)
      value = file_or_arn
    }
  ]

  // additional init config files ARNs from S3 to be used in an IAM policy for the task role
  s3_init_file_arns   = [for conf in local.init_config_files : conf.value if can(regex("^arn:.*:s3:", conf.value))]
  s3_init_bucket_arns = distinct([for arn in local.s3_init_file_arns : split("/", arn)[0]])

  // optional FluentBit container for log aggregation
  fluentbit_container_defaults = {
    name                   = var.firelens.container_name
    image                  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecr-public/aws-observability/aws-for-fluent-bit:init-2.32.0.20240122"
    environment            = concat([{ name = "FLB_LOG_LEVEL", value = "error" }], local.init_config_files)
    essential              = true
    mountPoints            = []
    portMappings           = []
    readonlyRootFilesystem = false
    user                   = startswith(upper(var.operating_system_family), "WINDOWS") ? null : "0:1337"
    volumesFrom            = []

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
  count = var.firelens.enabled && var.task_role_arn == "" && length(local.s3_init_file_arns) > 0 && var.attach_fluentbit_init_policy ? 1 : 0

  // allow reading the init config files from S3
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = local.s3_init_file_arns
  }

  // allow listing the S3 buckets containing the init config files
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = local.s3_init_bucket_arns
  }
}

resource "aws_iam_policy" "fluent_bit_config_access" {
  count = var.firelens.enabled && var.task_role_arn == "" && length(local.s3_init_file_arns) > 0 && var.attach_fluentbit_init_policy ? 1 : 0

  name   = "fluent-bit-config-access-${var.service_name}-${data.aws_region.current.name}"
  path   = "/ecs/task-role/"
  policy = data.aws_iam_policy_document.fluent_bit_config_access[count.index].json
}

resource "aws_iam_role_policy_attachment" "fluent_bit_config_access" {
  count = var.firelens.enabled && var.task_role_arn == "" && length(local.s3_init_file_arns) > 0 && var.attach_fluentbit_init_policy ? 1 : 0

  role       = aws_iam_role.ecs_task_role[count.index].name
  policy_arn = aws_iam_policy.fluent_bit_config_access[count.index].arn
}
