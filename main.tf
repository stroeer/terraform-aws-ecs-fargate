data "aws_lb" "public" {
  for_each = var.create_ingress_security_group ? toset([for target in var.target_groups : lookup(target, "load_balancer_arn", "")]) : []
  arn      = each.value
}

locals {
  ingress_targets = flatten(
    [
      for target in var.target_groups : flatten(
        [
          [
            {
              # allow backend_port traffic
              from_port                = lookup(target, "backend_port")
              to_port                  = lookup(target, "backend_port")
              protocol                 = "tcp"
              source_security_group_id = tolist(data.aws_lb.public[lookup(target, "load_balancer_arn")].security_groups)[0]
              prefix                   = "backend_port"
            }
          ],
          lookup(target, "health_check", null) != null &&
          lookup(target["health_check"], "port", "traffic-port") != lookup(target, "backend_port", ) &&
          lookup(target["health_check"], "port", "traffic-port") != "traffic-port"
          ? [
            {
              # if health_check_port set and different from backend_port, also allow traffic
              from_port                = target["health_check"]["port"]
              to_port                  = target["health_check"]["port"]
              protocol                 = "tcp"
              source_security_group_id = tolist(data.aws_lb.public[lookup(target, "load_balancer_arn")].security_groups)[0]
              prefix                   = "health_check_port"
            }
          ] : []
        ]
      ) if var.create_ingress_security_group
    ]
  )

  additional_sidecars   = [for s in var.additional_container_definitions : jsonencode(s)]
  container_definitions = "[${join(",", concat(compact([local.app_container, local.envoy_container, local.fluentbit_container, local.otel_container])), compact(local.additional_sidecars))}]"
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = var.subnet_tags != null ? var.subnet_tags : {
    Tier = var.assign_public_ip ? "public" : "private"
  }
}

module "sg" {
  count   = var.create_ingress_security_group && length(local.ingress_targets) > 0 ? 1 : 0
  source  = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name                                  = "${var.service_name}-inbound-from-target-groups"
  description                           = "Allow TCP from target groups to port"
  ingress_with_source_security_group_id = local.ingress_targets
  use_name_prefix                       = false
  vpc_id                                = var.vpc_id
}

resource "aws_security_group_rule" "trusted_egress_attachment" {
  for_each                 = { for route in local.ingress_targets : "${route["prefix"]}-${route["source_security_group_id"]}" => route }
  type                     = "egress"
  from_port                = each.value["from_port"]
  to_port                  = each.value["to_port"]
  protocol                 = "tcp"
  description              = "Attached from ${module.sg[0].this_security_group_name} (${each.value["prefix"]})"
  source_security_group_id = module.sg[0].this_security_group_id
  security_group_id        = each.value["source_security_group_id"]
}

resource "aws_ecs_service" "this" {
  cluster                            = var.cluster_id
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  desired_count                      = var.desired_count
  enable_execute_command             = var.enable_execute_command
  force_new_deployment               = var.force_new_deployment
  health_check_grace_period_seconds  = 0
  launch_type                        = var.capacity_provider_strategy != null ? null : "FARGATE"
  name                               = var.service_name
  platform_version                   = var.platform_version
  propagate_tags                     = "SERVICE"
  tags                               = var.tags
  task_definition                    = "${aws_ecs_task_definition.this.family}:${max(aws_ecs_task_definition.this.revision, data.aws_ecs_task_definition.this.revision)}"

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy != null ? var.capacity_provider_strategy : []

    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_circuit_breaker != null ? [true] : []

    content {
      enable   = var.deployment_circuit_breaker.enable
      rollback = var.deployment_circuit_breaker.rollback
    }
  }

  dynamic "load_balancer" {
    for_each = aws_alb_target_group.main

    content {
      container_name   = local.container_name
      container_port   = load_balancer.value.port
      target_group_arn = load_balancer.value.arn
    }
  }

  network_configuration {
    assign_public_ip = var.assign_public_ip
    security_groups  = concat(concat(var.security_groups, [for sg in module.sg : sg.this_security_group_id]), [])
    subnets          = data.aws_subnets.selected.ids
  }

  dynamic "service_registries" {
    for_each = var.service_discovery_dns_namespace != "" ? [true] : []

    content {
      registry_arn   = aws_service_discovery_service.this[0].arn
      container_name = var.container_name
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_task_definition" "this" {
  depends_on = [
    aws_iam_role.task_execution_role,
    aws_iam_role.ecs_task_role
  ]

  container_definitions    = local.container_definitions
  cpu                      = var.cpu
  execution_role_arn       = var.task_execution_role_arn == "" ? aws_iam_role.task_execution_role[0].arn : var.task_execution_role_arn
  family                   = var.service_name
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = var.requires_compatibilities
  tags                     = var.tags
  task_role_arn            = var.task_role_arn == "" ? aws_iam_role.ecs_task_role[0].arn : var.task_role_arn

  dynamic "volume" {
    for_each = var.efs_volumes

    content {
      name = volume.value["name"]

      efs_volume_configuration {
        file_system_id     = volume.value["file_system_id"]
        root_directory     = try(volume.value["root_directory"], null)
        transit_encryption = try(volume.value["transit_encryption"], "DISABLED")

        dynamic "authorization_config" {
          for_each = try(volume.value["authorization_config"], null) != null ? [true] : []

          content {
            access_point_id = try(volume.value["authorization_config"].access_point_id, null)
            iam             = try(volume.value["authorization_config"].iam, null)
          }
        }
      }
    }
  }

  dynamic "proxy_configuration" {
    for_each = try(var.app_mesh.enabled, false) ? [true] : []

    content {
      container_name = var.app_mesh.container_name
      type           = "APPMESH"

      properties = {
        AppPorts         = var.container_port
        EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
        IgnoredGID       = "1337"
        ProxyEgressPort  = 15001
        ProxyIngressPort = 15000
      }
    }
  }
}

# Simply specify the family to find the latest ACTIVE revision in that family.
data "aws_ecs_task_definition" "this" {
  depends_on      = [aws_ecs_task_definition.this]
  task_definition = aws_ecs_task_definition.this.family
}

locals {
  container_name = var.container_name == "" ? var.service_name : var.container_name
}

module "ecr" {
  source = "./modules/ecr"
  count  = var.create_ecr_repository ? 1 : 0

  custom_lifecycle_policy         = var.ecr_custom_lifecycle_policy
  enable_default_lifecycle_policy = var.ecr_enable_default_lifecycle_policy
  force_delete                    = var.ecr_force_delete
  image_scanning_configuration    = var.ecr_image_scanning_configuration
  image_tag_mutability            = var.ecr_image_tag_mutability
  name                            = var.ecr_repository_name != "" ? var.ecr_repository_name : var.service_name
  tags                            = var.tags
}

module "code_deploy" {
  source = "./modules/deployment"
  count  = var.create_deployment_pipeline && (var.create_ecr_repository || var.ecr_repository_name != "") ? 1 : 0

  cluster_name                            = var.cluster_id
  container_name                          = local.container_name
  codestar_notifications_detail_type      = var.codestar_notifications_detail_type
  codestar_notifications_event_type_ids   = var.codestar_notifications_event_type_ids
  codestar_notifications_target_arn       = var.codestar_notifications_target_arn
  codestar_notification_kms_master_key_id = var.codestar_notifications_kms_master_key_id
  ecr_repository_name                     = var.create_ecr_repository ? module.ecr[count.index].name : var.ecr_repository_name
  ecr_image_tag                           = var.ecr_image_tag
  service_name                            = var.service_name
  code_build_role                         = var.code_build_role_name
  code_pipeline_role                      = var.code_pipeline_role_name
  artifact_bucket                         = var.code_pipeline_artifact_bucket
  artifact_bucket_server_side_encryption  = var.code_pipeline_artifact_bucket_sse

  tags = var.tags
}

##############
# AUTOSCALING
##############

resource "aws_appautoscaling_target" "ecs" {
  count = var.appautoscaling_settings != null ? 1 : 0

  max_capacity       = lookup(var.appautoscaling_settings, "max_capacity", var.desired_count)
  min_capacity       = lookup(var.appautoscaling_settings, "min_capacity", var.desired_count)
  resource_id        = "service/${var.cluster_id}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs" {
  count = var.appautoscaling_settings != null ? 1 : 0

  name               = "${var.service_name}-auto-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = lookup(var.appautoscaling_settings, "target_value")
    disable_scale_in   = lookup(var.appautoscaling_settings, "disable_scale_in", false)
    scale_in_cooldown  = lookup(var.appautoscaling_settings, "scale_in_cooldown", 300)
    scale_out_cooldown = lookup(var.appautoscaling_settings, "scale_out_cooldown", 30)

    predefined_metric_specification {
      predefined_metric_type = lookup(var.appautoscaling_settings, "predefined_metric_type", "ECSServiceAverageCPUUtilization")
    }
  }
}
