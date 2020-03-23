variable "region" {
}

provider "aws" {
  region = var.region
}

locals {
  service_name = "test-frontend"
}
module "service" {
  source = "../.."

  cluster_id            = "k8"
  alb_listener_priority = 666
  health_check_endpoint = "/actuator/info"
  desired_count         = 0
  service_name          = local.service_name
  container_port        = 9000
  assign_public_ip      = true
  container_definitions = <<DOC
[
  {
    "name": "${local.service_name}",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.service_name}:4",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [ {"containerPort": 9000, "protocol": "tcp"} ],
    "environment": [
      {
        "name": "APPLICATION_SECRET",
        "value": ">a{|jiT:zW,KnV%FT5km9,/F.#7HYpBJ"
      }
    ]
  }
]
DOC
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

terraform {
  backend "s3" {
    encrypt        = true
    dynamodb_table = terraform-lock
  }
}
