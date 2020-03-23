# this could also be a separate (sub-module) instantiated (even conditionally) in main.tf

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

resource "aws_alb_target_group" "public" {
  #  count                = var.use_code_deploy ? 0 : 1
  name                 = "${var.service_name}-public"
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.selected.id
  deregistration_delay = 5
  target_type          = "ip"
  tags                 = local.default_tags
  health_check {
    path              = var.health_check_endpoint
    protocol          = "HTTP"
    interval          = 6
    healthy_threshold = 2
  }
}

resource "aws_alb_target_group" "private" {
  # count                = var.use_code_deploy ? 0 : 1
  name                 = "${var.service_name}-private"
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.selected.id
  deregistration_delay = 5
  target_type          = "ip"
  health_check {
    path              = var.health_check_endpoint
    protocol          = "HTTP"
    interval          = 6
    healthy_threshold = 2
  }

  tags = local.default_tags
}

resource "aws_alb_listener_rule" "public" {
  #  count        = var.use_code_deploy ? 0 : 1
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
}

resource "aws_alb_listener_rule" "private" {
  # count        = var.use_code_deploy ? 0 : 1
  # listener_arn = data.aws_lb_listener.private[count.index].arn
  listener_arn = data.aws_lb_listener.private.arn
  priority     = var.alb_listener_priority

  action {
    type = "forward"
    # target_group_arn = aws_alb_target_group.private[count.index].arn
    target_group_arn = aws_alb_target_group.private.arn
  }
  # todo(mana): once dns is ready, use host_header
  condition {
    host_header {
      values = [trimsuffix("${var.service_name}.${data.aws_route53_zone.internal.name}", ".")]
    }
  }
}
