# service_name.service-discovery.vpc.internal.
resource "aws_service_discovery_service" "this" {
  name = var.service_name
  dns_config {
    namespace_id = data.terraform_remote_state.ecs.outputs.service_discovery_private_dns_namespace_id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
    key    = "regional/ecs_cluster/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
