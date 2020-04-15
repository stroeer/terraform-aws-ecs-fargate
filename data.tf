# add data sources used in more than one tf file here

locals {
  root_path = split("/", abspath(path.root))
  tf_stack  = join("/", slice(local.root_path, length(local.root_path) - 1, length(local.root_path)))
  default_tags = {
    managed_by = "terraform",
    source     = "github.com/stroeer/terraform-aws-ecs-fargate"
    tf_stack   = local.tf_stack,
    tf_module  = basename(abspath(path.module))
    service    = var.service_name
  }
}

data "aws_vpc" "selected" {
  tags = {
    Name = "main"
  }
}
