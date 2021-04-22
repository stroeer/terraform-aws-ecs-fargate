locals {
  service_name = "httpd"
}
// AZs available in the selected zone
data "aws_availability_zones" "available" {
  state = "available"
}

// this is the VPC in which the ALB will be placed
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"

  name = "simple-example"

  cidr = "10.0.0.0/16"

  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  public_subnet_tags = {
    // the service module will search subnets with this tag
    // to place the fargate ENI (elastic network interface)
    Tier = "public"
  }
}

// allow ingress traffic IPv4/IPv6 on port 80 (HTTP)
module "lb_security_group_public" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  // the fargate ENI will use this security group
  // it also needs access to the ALB to allow traffic
  name            = "fargate-allow-alb-traffic"
  use_name_prefix = false
  description     = "Security group for example usage with ALB"
  vpc_id          = module.vpc.vpc_id

  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]
  ingress_rules            = ["http-80-tcp"]
  egress_rules             = ["all-all"]
}

// plain ALB in the public subnet
resource "aws_lb" "main" {
  name               = "main"
  load_balancer_type = "application"
  security_groups    = [module.vpc.default_security_group_id, module.lb_security_group_public.this_security_group_id]
  subnets            = module.vpc.public_subnets
}

// ALB listener on port 80 (HTTP)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

// our ecs cluster
resource "aws_ecs_cluster" "main" {
  name = "k9"
}

// dummy httpd service
module "service" {
  source = "../../"

  assign_public_ip           = true
  cluster_id                 = aws_ecs_cluster.main.id
  container_port             = 80
  create_deployment_pipeline = false
  desired_count              = 1
  service_name               = local.service_name
  vpc_id                     = module.vpc.vpc_id

  target_groups = [
    {
      name             = "${local.service_name}-public"
      backend_port     = 80
      backend_protocol = "HTTP"
      target_type      = "ip"
      health_check = {
        enabled = true
        path    = "/"
      }
    }
  ]

  https_listener_rules = [{
    listener_arn = aws_lb_listener.http.arn

    priority = 42
    actions = [{
      type               = "forward"
      target_group_index = 0
    }]
    conditions = [{
      path_patterns = ["/"]
    }]
  }]

  container_definitions = jsonencode([
    {
      command : [
        "/bin/sh -c \"echo '<html> <head> <title>Hello from httpd service</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
      ],
      cpu : 256,
      entryPoint : ["sh", "-c"],
      essential : true,
      image : "httpd:2.4",
      memory : 512,
      name : local.service_name,
      portMappings : [{
        containerPort : 80
        hostPort : 80
        protocol : "tcp"
      }]
    }
  ])

  ecr = {
    image_tag_mutability = "IMMUTABLE"
    image_scanning_configuration = {
      scan_on_push = true
    }
  }
}
