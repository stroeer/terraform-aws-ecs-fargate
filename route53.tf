resource "aws_service_discovery_service" "this" {
  count = var.service_discovery_dns_namespace != "" ? 1 : 0

  description = "Route 53 Auto Naming Service for ${var.service_name}"
  name        = var.service_name

  dns_config {
    namespace_id   = var.service_discovery_dns_namespace
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  // removing the deprecated `failure_threshold` attribute will force a recreation of the resource
  health_check_custom_config {
    failure_threshold = 1
  }
}
