locals {
  container_port = 8000
  image_tag      = "production"
  service_name   = "${random_pet.this.id}-service"
}

resource "random_pet" "this" {
  length = 2
}

resource "aws_ecs_cluster" "this" {
  name = "${random_pet.this.id}-cluster"
}

module "vpc" {
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version = ">= 3.18"

  azs                  = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr                 = "10.0.0.0/16"
  enable_dns_hostnames = true
  name                 = random_pet.this.id
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }
}

// see https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html for necessary endpoints to run Fargate tasks
module "vpc_endpoints" {
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = ">= 3.18"

  security_group_ids = [data.aws_security_group.default.id]
  vpc_id             = module.vpc.vpc_id

  endpoints = {
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }

    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }

    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }

    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
    }
  }
}

module "alb_security_group_public" {
  source  = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  version = ">= 4.17"

  name            = "fargate-allow-alb-traffic"
  use_name_prefix = false
  description     = "Security group for example usage with ALB"
  vpc_id          = module.vpc.vpc_id

  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]
  ingress_rules            = ["http-80-tcp"]
  egress_rules             = ["all-all"]
}

#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "public" {
  drop_invalid_header_fields = true
  load_balancer_type         = "application"
  name                       = random_pet.this.id
  security_groups            = [module.vpc.default_security_group_id, module.alb_security_group_public.security_group_id]
  subnets                    = module.vpc.public_subnets
}

#tfsec:ignore:aws-elb-http-not-used
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Request was not routed."
      status_code  = 400
    }
  }
}

module "service" {
  source = "../../"

  cpu                           = 256
  cluster_id                    = aws_ecs_cluster.this.id
  container_port                = local.container_port
  create_ingress_security_group = false
  create_deployment_pipeline    = false
  desired_count                 = 1
  ecr_force_delete              = true
  memory                        = 512
  service_name                  = local.service_name
  vpc_id                        = module.vpc.vpc_id

  // configure autoscaling for this service
  appautoscaling_settings = {
    max_capacity           = 4
    min_capacity           = 1
    predefined_metric_type = "ECSServiceAverageCPUUtilization"
    target_value           = 25
  }

  // overwrite the default container definition or add further task definition parameters
  container_definition_overwrites = {
    readonlyRootFilesystem = false
  }

  // add listener rules that determine how the load balancer routes requests to its registered targets.
  https_listener_rules = [{
    listener_arn = aws_lb_listener.http.arn

    actions = [{
      type               = "forward"
      target_group_index = 0
    }]

    conditions = [{
      path_patterns = ["/"]
    }]
  }]

  // add a target group to route ALB traffic to this service
  target_groups = [
    {
      name              = "${local.service_name}-public"
      backend_protocol  = "HTTP"
      backend_port      = local.container_port
      load_balancer_arn = aws_lb_listener.http.load_balancer_arn
      target_type       = "ip"

      health_check = {
        enabled  = true
        path     = "/"
        protocol = "HTTP"
      }
    }
  ]
}

resource "null_resource" "initial_image" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${module.service.ecr_repository_url}"
  }

  provisioner "local-exec" {
    command     = "docker build --tag ${module.service.ecr_repository_url}:${local.image_tag} ."
    working_dir = "${path.module}/../fixtures/context"
  }

  provisioner "local-exec" {
    command     = "docker push --all-tags ${module.service.ecr_repository_url}"
    working_dir = "${path.module}/../fixtures/context"
  }
}
