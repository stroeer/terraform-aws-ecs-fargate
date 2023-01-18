locals {
  // mandatory app container with overridable defaults
  app_container_defaults = {
    dependsOn              = var.app_mesh.enabled ? [{ containerName = var.app_mesh.container_name, condition = "HEALTHY" }] : []
    essential              = true
    image                  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.service_name}:production"
    name                   = var.service_name
    readonlyRootFilesystem = true
    mountPoints            = []
    user                   = "0"
    volumesFrom            = []

    logConfiguration = var.firelens.enabled && var.firelens.opensearch_host != "" ? {
      logDriver = "awsfirelens",
      options = {
        Aws_Auth        = "Off"
        Aws_Region      = data.aws_region.current.name
        Host            = var.firelens.opensearch_host
        Logstash_Format = "true"
        Logstash_Prefix = "${var.service_name}-app"
        Name            = "opensearch"
        Port            = "443"
        tls             = "On"
        Trace_Output    = "Off"
      }
      } : (var.cloudwatch_logs.enabled ? {
        logDriver = "awslogs"
        options = {
          awslogs-group : aws_cloudwatch_log_group.containers[0].name
          awslogs-region : data.aws_region.current.name
          awslogs-stream-prefix : "${var.service_name}-app"
        }
    } : null)

    portMappings = [
      {
        hostPort      = var.container_port,
        containerPort = var.container_port,
        protocol      = "tcp"
      }
    ]

    ulimits = [
      {
        name      = "nofile"
        softLimit = 1024 * 32, // default is 1024
        hardLimit = 4096 * 32  // default is 4096
      }
    ]
  }

  app_container = jsonencode(module.container_definition.merged)
}

module "container_definition" {
  source  = "Invicton-Labs/deepmerge/null"
  version = "0.1.5"

  maps = [
    local.app_container_defaults,
    var.container_definition_overwrites
  ]
}
