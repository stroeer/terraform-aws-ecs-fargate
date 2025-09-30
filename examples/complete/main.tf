locals {
  container_port = 8000
  image_tag      = "production"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  secrets = {
    foo = "CHANGE_ME"
    bar = "CHANGE_ME"
  }
}

resource "random_pet" "this" {
  length = 1
}

resource "aws_ecs_cluster" "this" {
  name = random_pet.this.id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  azs             = local.azs
  cidr            = local.vpc_cidr
  name            = random_pet.this.id
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  enable_deletion_protection = false
  load_balancer_type         = "application"
  name                       = random_pet.this.id
  subnets                    = module.vpc.public_subnets
  vpc_id                     = module.vpc.vpc_id

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      fixed_response = {
        content_type = "text/plain"
        message_body = "Request was not routed."
        status_code  = 404
      }
    }
  }
}

resource "aws_ssm_parameter" "secrets" {
  for_each = local.secrets

  name  = "/${random_pet.this.id}/${each.key}"
  type  = "SecureString"
  value = each.value
}

module "service" {
  source     = "../../"
  depends_on = [module.vpc]

  availability_zone_rebalancing                         = "ENABLED"
  cpu                                                   = 256
  cpu_architecture                                      = "ARM64"
  cluster_id                                            = aws_ecs_cluster.this.id
  container_port                                        = local.container_port
  create_ingress_security_group                         = true
  create_deployment_pipeline                            = false
  desired_count                                         = 2
  ecr_force_delete                                      = true
  ecr_image_tag                                         = local.image_tag
  ecr_cross_region_replication_destination_region_names = ["eu-north-1"]
  memory                                                = 512
  service_name                                          = random_pet.this.id
  security_groups                                       = [aws_security_group.egress_all.id]
  vpc_id                                                = module.vpc.vpc_id

  // (optionally) enable ECS Exec, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html
  enable_execute_command = true

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

    secrets = [
      for name, _ in local.secrets : {
        name      = name
        valueFrom = aws_ssm_parameter.secrets[name].arn
      }
    ]
  }

  // add listener rules that determine how the load balancer routes requests to its registered targets.
  https_listener_rules = [{
    listener_arn = module.alb.listeners["http"].arn

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
      name_prefix       = "${substr(random_pet.this.id, 0, 5)}-"
      backend_protocol  = "HTTP"
      backend_port      = local.container_port
      load_balancer_arn = module.alb.arn
      target_type       = "ip"

      health_check = {
        enabled  = true
        path     = "/"
        protocol = "HTTP"
      }
    }
  ]
}

resource "aws_security_group" "egress_all" {
  name_prefix = "${random_pet.this.id}-egress-all-"
  description = "Allow all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  # make sure to secure traffic in production environments
  # see https://avd.aquasec.com/misconfig/aws/ec2/avd-aws-0104/#Terraform
  #trivy:ignore:AVD-AWS-0104
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "initial_image" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  }

  provisioner "local-exec" {
    command     = "docker buildx build --tag ${module.service.ecr_repository_url}:${local.image_tag} --platform linux/amd64,linux/arm64 --push ."
    working_dir = "${path.module}/../fixtures/context"
  }
}
