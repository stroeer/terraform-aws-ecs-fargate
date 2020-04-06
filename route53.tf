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

data "aws_route53_zone" "internal" {
  private_zone = true
  vpc_id       = data.aws_vpc.selected.id
  name         = "vpc.internal."
}

# service_name.vpc.internal.
resource "aws_route53_record" "internal" {
  name    = var.service_name
  type    = "CNAME"
  zone_id = data.aws_route53_zone.internal.zone_id
  ttl     = 300
  records = [data.aws_lb.private.dns_name]
}

data "aws_route53_zone" "external" {
  name = "buzz.t-online.delivery."
}

# service_name.buzz.t-online.delivery
resource "aws_route53_record" "external" {
  name    = var.service_name
  type    = "CNAME"
  zone_id = data.aws_route53_zone.external.zone_id
  ttl     = 300
  records = [data.aws_lb.public.dns_name]
}
