# the VPC to be used based on the Name tag
data "aws_vpc" "selected" {
  tags = {
    Name = "main"
  }
}
# the subnets to be used based on the Tier tag
data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_vpc.selected.id
  tags = {
    Tier = var.assign_public_ip ? "public" : "private"
  }
}

## the VPC's default SG must be attached to allow traffic from/to AWS endpoints like ECR
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.selected.id
}

# The SG that allows ingress traffic from ALB
data "aws_security_group" "fargate" {
  name   = "fargate-allow-alb-traffic"
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_ecs_service" "this" {
  name                               = var.service_name
  cluster                            = var.cluster_id
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  task_definition                    = "${aws_ecs_task_definition.this.family}:${max("${aws_ecs_task_definition.this.revision}", "${data.aws_ecs_task_definition.this.revision}")}"

  network_configuration {
    subnets          = data.aws_subnet_ids.selected.ids
    security_groups  = [data.aws_security_group.default.id, data.aws_security_group.fargate.id]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = list(aws_alb_target_group.public.arn, aws_alb_target_group.private.arn)
    content {
      container_name   = local.container_name
      container_port   = var.container_port
      target_group_arn = load_balancer.value
    }
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
    container_name = var.container_name
  }

  health_check_grace_period_seconds = 0
  propagate_tags                    = "SERVICE"
  tags                              = local.default_tags
}

resource "aws_ecs_task_definition" "this" {
  family                = var.service_name
  task_role_arn         = aws_iam_role.ecs_task_role.arn
  execution_role_arn    = data.aws_iam_role.task_execution_role.arn
  network_mode          = "awsvpc"
  cpu                   = var.cpu
  memory                = var.memory
  container_definitions = var.container_definitions
  tags                  = local.default_tags

  dynamic "proxy_configuration" {
    for_each = var.with_appmesh ? [var.with_appmesh] : []
    content {
      container_name = "envoy"
      type           = "APPMESH"

      properties = {
        AppPorts         = "9000"
        EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
        IgnoredUID       = "1337"
        ProxyEgressPort  = 15001
        ProxyIngressPort = 15000
      }
    }
  }
}

# Simply specify the family to find the latest ACTIVE revision in that family.
data "aws_ecs_task_definition" "this" {
  task_definition = aws_ecs_task_definition.this.family
  depends_on      = [aws_ecs_task_definition.this]
}

resource "aws_alb_target_group" "public" {
  name                 = "${var.service_name}-public"
  port                 = var.with_appmesh ? 15000 : var.container_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.selected.id
  deregistration_delay = 5
  target_type          = "ip"
  tags                 = local.default_tags
  health_check {
    path                = var.health_check_endpoint
    port                = var.container_port
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_alb_target_group" "private" {
  name                 = "${var.service_name}-private"
  port                 = var.with_appmesh ? 15000 : var.container_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.selected.id
  deregistration_delay = 5
  target_type          = "ip"
  tags                 = local.default_tags
  health_check {
    path                = var.health_check_endpoint
    port                = var.container_port
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

data "aws_lb" "public" {
  name = "public"
}

data "aws_lb_listener" "public" {
  load_balancer_arn = data.aws_lb.public.arn
  port              = 443
}

data "aws_lb" "private" {
  name = "private"
}

data "aws_lb_listener" "private" {
  load_balancer_arn = data.aws_lb.private.arn
  port              = 80
}

resource "aws_alb_listener_rule" "public" {
  listener_arn = data.aws_lb_listener.public.arn
  priority     = var.alb_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.public.arn
  }
  condition {
    host_header {
      values = [trimsuffix("${var.service_name}.${data.aws_route53_zone.external.name}", ".")]
    }
  }
  depends_on = [
    aws_alb_target_group.public
  ]
}

resource "aws_alb_listener_rule" "private" {
  listener_arn = data.aws_lb_listener.private.arn
  priority     = var.alb_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.private.arn
  }

  condition {
    host_header {
      values = [trimsuffix("${var.service_name}.${data.aws_route53_zone.internal.name}", ".")]
    }
  }

  depends_on = [
    aws_alb_target_group.private
  ]
}

locals {
  root_path = split("/", abspath(path.root))
  tf_stack  = join("/", slice(local.root_path, length(local.root_path) - 1, length(local.root_path)))
  default_tags = {
    managed_by = "terraform",
    source     = "github.com/stroeer/buzzgate"
    tf_stack   = local.tf_stack,
    tf_module  = basename(abspath(path.module))
    service    = var.service_name
  }
  container_name = var.container_name == "" ? var.service_name : var.container_name
}

module "ecr" {
  source = "./modules/ecr"

  image_scanning_configuration = var.ecr.image_scanning_configuration
  image_tag_mutability         = var.ecr.image_tag_mutability
  name                         = var.service_name
  tags                         = local.default_tags
}

module "code_deploy" {
  source  = "./modules/deployment"
  enabled = var.create_deployment_pipeline

  cluster_name        = var.cluster_id
  ecr_repository_name = module.ecr.name
  service_name        = var.service_name
  tags                = local.default_tags
}

module "logs" {
  source  = "./modules/logs"
  enabled = var.create_log_streaming

  service_name = var.service_name
  tags         = local.default_tags
}
