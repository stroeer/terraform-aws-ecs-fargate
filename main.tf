data "aws_subnet_ids" "selected" {
  tags = {
    Tier = var.assign_public_ip ? "public" : "private"
  }
  vpc_id = data.aws_vpc.selected.id
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
  cluster                            = var.cluster_id
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = var.desired_count
  health_check_grace_period_seconds  = 0
  launch_type                        = "FARGATE"
  name                               = var.service_name
  propagate_tags                     = "SERVICE"
  tags                               = local.default_tags
  task_definition                    = "${aws_ecs_task_definition.this.family}:${max("${aws_ecs_task_definition.this.revision}", "${data.aws_ecs_task_definition.this.revision}")}"

  dynamic "load_balancer" {
    for_each = list(aws_alb_target_group.public.arn, aws_alb_target_group.private.arn)
    content {
      container_name   = local.container_name
      container_port   = var.container_port
      target_group_arn = load_balancer.value
    }
  }

  network_configuration {
    subnets          = data.aws_subnet_ids.selected.ids
    security_groups  = [data.aws_security_group.default.id, data.aws_security_group.fargate.id]
    assign_public_ip = var.assign_public_ip
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
    container_name = var.container_name
  }
}

data "aws_iam_role" "task_execution_role" {
  name = "ssm_ecs_task_execution_role"
}

resource "aws_ecs_task_definition" "this" {
  container_definitions = var.container_definitions
  cpu                   = var.cpu
  execution_role_arn    = data.aws_iam_role.task_execution_role.arn
  family                = var.service_name
  memory                = var.memory
  network_mode          = "awsvpc"
  tags                  = local.default_tags
  task_role_arn         = aws_iam_role.ecs_task_role.arn

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
  depends_on      = [aws_ecs_task_definition.this]
  task_definition = aws_ecs_task_definition.this.family
}

locals {
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
  code_build_role     = var.code_build_role_name
  code_pipeline_role  = var.code_pipeline_role_name
  artifact_bucket     = var.code_pipeline_artifact_bucket
  tags                = local.default_tags
}

module "logs" {
  source  = "./modules/logs"
  enabled = var.create_log_streaming

  domain_name                                   = var.logs_domain_name
  firehose_delivery_stream_s3_backup_bucket_arn = var.firehose_delivery_stream_s3_backup_bucket_arn
  service_name                                  = var.service_name
  tags                                          = local.default_tags
  task_role_name                                = aws_iam_role.ecs_task_role.name
}
