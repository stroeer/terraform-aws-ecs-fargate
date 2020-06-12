data "aws_lb" "public" {
  count = var.alb_attach_public_target_group ? 1 : 0
  name  = "public"
}

data "aws_lb_listener" "public" {
  count             = var.alb_attach_public_target_group ? 1 : 0
  load_balancer_arn = data.aws_lb.public[count.index].arn
  port              = 443
}

data "aws_lb_listener" "public_80" {
  count             = var.alb_attach_public_target_group ? 1 : 0
  load_balancer_arn = data.aws_lb.public[count.index].arn
  port              = 80
}

resource "aws_alb_target_group" "public" {
  count = var.alb_attach_public_target_group ? 1 : 0

  deregistration_delay = 5
  name                 = "${var.service_name}-public"
  port                 = var.container_port
  protocol             = lookup(var.health_check, "protocol", "HTTP")
  tags                 = local.default_tags
  target_type          = "ip"
  vpc_id               = data.aws_vpc.selected.id

  dynamic "health_check" {
    for_each = [var.health_check]
    content {
      enabled             = lookup(health_check.value, "enabled", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      interval            = lookup(health_check.value, "interval", null)
      matcher             = lookup(health_check.value, "matcher", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
    }
  }
}

resource "aws_alb_listener_rule" "public" {
  count = var.alb_attach_public_target_group ? 1 : 0

  listener_arn = data.aws_lb_listener.public[count.index].arn
  priority     = var.alb_listener_priority

  dynamic "action" {
    for_each = var.alb_cogino_pool_arn == "" ? [/*noop*/] : ["enabled"]
    content {
      type = "authenticate-cognito"
      authenticate_cognito {
        user_pool_arn       = var.alb_cogino_pool_arn
        user_pool_client_id = var.alb_cogino_pool_client_id
        user_pool_domain    = var.alb_cogino_pool_domain
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.public[count.index].arn
  }

  condition {
    host_header {
      values = [trimsuffix("${var.service_name}-${data.aws_region.current.name}.${data.aws_route53_zone.external[count.index].name}", ".")]
    }
  }
}

resource "aws_alb_listener_rule" "public_80" {
  count = var.alb_attach_public_target_group ? 1 : 0

  listener_arn = data.aws_lb_listener.public_80[count.index].arn
  priority     = var.alb_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.public[count.index].arn
  }

  condition {
    host_header {
      values = [trimsuffix("${var.service_name}.${data.aws_route53_zone.external[count.index].name}", ".")]
    }
  }

  condition {
    http_header {
      http_header_name = "X-Do-Not-Redirect"
      values           = ["true"]
    }
  }
}

data "aws_lb" "private" {
  count = var.alb_attach_private_target_group ? 1 : 0
  name  = "private"
}

data "aws_lb_listener" "private" {
  count             = var.alb_attach_private_target_group ? 1 : 0
  load_balancer_arn = data.aws_lb.private[count.index].arn
  port              = 80
}

resource "aws_alb_target_group" "private" {
  count = var.alb_attach_private_target_group ? 1 : 0

  deregistration_delay = 5
  name                 = "${var.service_name}-private"
  port                 = var.container_port
  protocol             = lookup(var.health_check, "protocol", "HTTP")
  tags                 = local.default_tags
  target_type          = "ip"
  vpc_id               = data.aws_vpc.selected.id

  dynamic "health_check" {
    for_each = [var.health_check]
    content {
      enabled             = lookup(health_check.value, "enabled", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      interval            = lookup(health_check.value, "interval", null)
      matcher             = lookup(health_check.value, "matcher", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
    }
  }
}

resource "aws_alb_listener_rule" "private" {
  count = var.alb_attach_private_target_group ? 1 : 0

  listener_arn = data.aws_lb_listener.private[count.index].arn
  priority     = var.alb_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.private[count.index].arn
  }

  condition {
    host_header {
      values = [trimsuffix("${var.service_name}.${data.aws_route53_zone.internal[count.index].name}", ".")]
    }
  }
}
