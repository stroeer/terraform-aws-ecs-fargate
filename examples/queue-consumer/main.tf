locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
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

  enable_nat_gateway = true
  single_nat_gateway = true

  private_subnet_tags = {
    Tier = "private"
  }
}

resource "aws_sqs_queue" "example" {
  name = "${random_pet.this.id}-queue"
}

# Example service that consumes from SQS queue without exposing any ports
module "queue_consumer_service" {
  source     = "../../"
  depends_on = [module.vpc]

  cluster_id   = aws_ecs_cluster.this.id
  service_name = "${random_pet.this.id}-queue-consumer"
  vpc_id       = module.vpc.vpc_id
  # Note: container_port is not specified - the service doesn't expose any ports
  create_ingress_security_group = false # No ingress needed for queue consumer
  create_deployment_pipeline    = false
  desired_count                 = 1
  ecr_force_delete              = true
  cpu                           = 256
  memory                        = 512
  assign_public_ip              = false
  security_groups               = [aws_security_group.egress_all.id]

  container_definition_overwrites = {
    environment = [
      {
        name  = "QUEUE_URL"
        value = aws_sqs_queue.example.url
      }
    ]
  }

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.example.arn
      }
    ]
  })
}

resource "aws_security_group" "egress_all" {
  name_prefix = "${random_pet.this.id}-egress-all-"
  description = "Allow all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  # Allow outbound traffic for SQS and other AWS services
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