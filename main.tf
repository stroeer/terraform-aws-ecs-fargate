locals {
  ingress_targets = flatten([
    for target in var.target_groups : [
      {
        # allow backend_port traffic
        from_port                = lookup(target, "backend_port")
        to_port                  = lookup(target, "backend_port")
        protocol                 = "tcp"
        source_security_group_id = tolist(data.aws_lb.public[lookup(target, "load_balancer_arn")].security_groups)[0]
        prefix                   = "backend_port"
      },
      lookup(target, "health_check", null) != null
      && lookup(target["health_check"], "port", "traffic-port") != lookup(target, "backend_port", )
      && lookup(target["health_check"], "port", "traffic-port") != "traffic-port"
      ? {
        # if health_check_port set and different from backend_port, also allow traffic
        from_port                = target["health_check"]["port"]
        to_port                  = target["health_check"]["port"]
        protocol                 = "tcp"
        source_security_group_id = tolist(data.aws_lb.public[lookup(target, "load_balancer_arn")].security_groups)[0]
        prefix                   = "health_check_port"
      } : {}
    ]
  ])
}

data "aws_security_group" "fargate_app" {
  name   = "fargate-allow-internal-traffic"
  vpc_id = var.vpc_id
}

data "aws_security_group" "all_outbound_tcp" {
  name   = "allow-outbound-tcp"
  vpc_id = var.vpc_id
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Tier = (var.assign_public_ip || var.requires_internet_access) ? "public" : "private"
  }
}

data "aws_lb" "public" {
  for_each = toset([for target in var.target_groups : lookup(target, "load_balancer_arn", "")])
  arn      = each.value
}

module "sg" {
  count   = length(local.ingress_targets) == 0 ? 0 : 1
  source  = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name            = "${var.service_name}-inbound-from-target-groups"
  description     = "Allow TCP from target groups to port"
  use_name_prefix = false
  vpc_id          = var.vpc_id

  ingress_with_source_security_group_id = local.ingress_targets
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
  force_new_deployment               = var.force_new_deployment
  health_check_grace_period_seconds  = 0
  launch_type                        = "FARGATE"
  name                               = var.service_name
  platform_version                   = var.platform_version
  propagate_tags                     = "SERVICE"
  tags                               = var.tags
  task_definition                    = "${aws_ecs_task_definition.this.family}:${max(aws_ecs_task_definition.this.revision, data.aws_ecs_task_definition.this.revision)}"

  dynamic "load_balancer" {
    for_each = aws_alb_target_group.main
    content {
      container_name   = local.container_name
      container_port   = load_balancer.value.port
      target_group_arn = load_balancer.value.arn
    }
  }

  network_configuration {
    subnets = data.aws_subnets.selected.ids
    security_groups = concat(concat(var.security_groups, [for sg in module.sg : sg.this_security_group_id]), [
      data.aws_security_group.fargate_app.id, data.aws_security_group.all_outbound_tcp.id
    ])
    assign_public_ip = var.assign_public_ip
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
    container_name = var.container_name
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

data "aws_iam_role" "task_execution_role" {
  name = "ssm_ecs_task_execution_role"
}

resource "aws_ecs_task_definition" "this" {
  container_definitions    = var.container_definitions
  cpu                      = var.cpu
  execution_role_arn       = data.aws_iam_role.task_execution_role.arn
  family                   = var.service_name
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = var.requires_compatibilities
  tags                     = var.tags
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  dynamic "proxy_configuration" {
    for_each = var.with_appmesh ? [var.with_appmesh] : []
    content {
      container_name = "envoy"
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
  count  = var.create_ecr_repo ? 1 : 0

  custom_lifecycle_policy         = var.ecr_custom_lifecycle_policy
  enable_default_lifecycle_policy = var.ecr_enable_default_lifecycle_policy
  image_scanning_configuration    = var.ecr.image_scanning_configuration
  image_tag_mutability            = var.ecr.image_tag_mutability
  name                            = var.service_name
  tags                            = var.tags
}

module "code_deploy" {
  source = "./modules/deployment"
  count  = var.create_deployment_pipeline && (var.create_ecr_repo || var.ecr_repository_name != "") ? 1 : 0

  cluster_name                            = var.cluster_id
  container_name                          = local.container_name
  codestar_notifications_detail_type      = var.codestar_notifications_detail_type
  codestar_notifications_event_type_ids   = var.codestar_notifications_event_type_ids
  codestar_notifications_target_arn       = var.codestar_notifications_target_arn
  codestar_notification_kms_master_key_id = var.codestar_notifications_kms_master_key_id
  ecr_repository_name                     = var.create_ecr_repo ? module.ecr[count.index].name : var.ecr_repository_name
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
  resource_id        = "service/${var.cluster_id}/${var.service_name}"
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
