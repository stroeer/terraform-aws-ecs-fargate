resource "aws_codedeploy_app" "this" {
  count            = var.use_code_deploy ? 1 : 0
  compute_platform = "ECS"
  name             = var.service_name
}

resource "aws_codedeploy_deployment_group" "example" {
  count                  = var.use_code_deploy ? 1 : 0
  app_name               = aws_codedeploy_app.this[count.index].name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = var.service_name
  service_role_arn       = aws_iam_role.code_deploy_role[count.index].arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.listener_arns[0]]
      }
      target_group {
        name = aws_alb_target_group.blue[count.index].name
      }
      target_group {
        name = aws_alb_target_group.green[count.index].name
      }
    }
    //    test_traffic_route {
    //      listener_arns = []
    //    }
  }
}

resource "aws_alb_target_group" "green" {
  count       = var.use_code_deploy ? 1 : 0
  # name must not exceed 32 characters (e.g. funkotron-applications-ecs-production is not allowed)
  name        = "${var.service_name}-green"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  #  tags                 = local.tags
  health_check {
    path = var.health_check_path
  }
}

# attach to either internal or external ALB listener
resource "aws_alb_listener_rule" "green" {
  count        = var.use_code_deploy ? 1 : 0
  listener_arn = var.listener_arns[0]

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.green[count.index].arn
  }

  condition {
    host_header {
      values = ["${var.service_name}.vpc.internal"]
    }
  }
}

resource "aws_alb_target_group" "blue" {
  count       = var.use_code_deploy ? 1 : 0
  name        = "${var.service_name}-blue"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  #  tags                 = local.tags
  health_check {
    path = var.health_check_path
  }
}

# attach to either internal or external ALB listener
resource "aws_alb_listener_rule" "blue" {
  count        = var.use_code_deploy ? 1 : 0
  listener_arn = var.listener_arns[0]

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue[count.index].arn
  }

  condition {
    host_header {
      values = ["${var.service_name}.vpc.internal"]
    }
  }
}