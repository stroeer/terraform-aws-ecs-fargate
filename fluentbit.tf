locals {
  // optional FluentBit container for log aggregation
  fluentbit_container_defaults = {
    name                   = var.firelens.container_name
    image                  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecr-public/aws-observability/aws-for-fluent-bit:2.32.0"
    essential              = true
    mountPoints            = []
    portMappings           = []
    readonlyRootFilesystem = false
    user                   = startswith(upper(var.operating_system_family), "WINDOWS") ? null : "0:1337"
    volumesFrom            = []

    environment = [
      // Valid values are: debug, info and error
      { name = " FLB_LOG_LEVEL", value = "error" }
    ],

    healthCheck = {
      retries = 3
      command = [
        "CMD-SHELL",
        "curl -s http://localhost:2020/api/v1/uptime | grep uptime_hr | grep -q running"
      ]
      timeout     = 2
      interval    = 5
      startPeriod = 10
    }


    firelensConfiguration = {
      type = "fluentbit"
      options = {
        enable-ecs-log-metadata : "true",
        config-file-type : "file",
        config-file-value : "/fluent-bit/config/envoy-json.conf"
      }
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
