# this could also be a separate (sub-module) instantiated (even conditionally) in main.tf

resource "aws_ecr_repository" "this" {
  name = var.service_name
}
