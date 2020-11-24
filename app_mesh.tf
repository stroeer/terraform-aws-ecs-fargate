data "aws_acmpca_certificate_authority" "root_ca" {
  arn = "arn:aws:acm-pca:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:certificate-authority/1b3cd270-9086-4c72-bfee-e8d308439481"
}
data "aws_acm_certificate" "internal" {
  domain   = "*.apps.local"
  statuses = ["ISSUED"]
}
locals {
  health_check_proto = lower(lookup(var.health_check, "protocol", "grpc"))
  app_mesh_proto     = contains(["http", "https"], local.health_check_proto) ? "http" : "grpc"
}
resource "aws_appmesh_virtual_node" "this" {
  count     = var.app_mesh_configuration.enabled ? 1 : 0
  mesh_name = local.mesh_name
  name      = var.service_name
  spec {
    dynamic backend {
      for_each = var.app_mesh_configuration.backends
      content {
        virtual_service {
          virtual_service_name = backend.value
          dynamic client_policy {
            ## activate tls context policy only when this service is within our domain
            for_each = length(regexall("\\.services\\.vpc\\.internal$", backend.value)) > 0 ? [1] : []
            content {
              tls {
                validation {
                  trust {
                    acm {
                      certificate_authority_arns = [
                        data.aws_acmpca_certificate_authority.root_ca.arn
                      ]
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    listener {
      health_check {
        protocol            = local.app_mesh_proto
        path                = lookup(var.health_check, "path", null)
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
      port_mapping {
        port     = var.container_port
        protocol = local.app_mesh_proto
      }
      tls {
        certificate {
          acm {
            certificate_arn = data.aws_acm_certificate.internal.arn
          }
        }
        mode = "STRICT"
      }
    }
    logging {
      access_log {
        file {
          path = "/dev/stdout"
        }
      }
    }
    service_discovery {
      aws_cloud_map {
        namespace_name = "apps.local"
        service_name   = var.service_name
      }
    }
  }
}

resource "aws_appmesh_route" "grpc" {
  for_each = lookup(var.app_mesh_configuration, "grpc_endpoints", {})

  mesh_name           = local.mesh_name
  name                = "${var.service_name}-${each.key}"
  virtual_router_name = var.app_mesh_configuration.virtual_router_name

  spec {
    # 1000 is default (lowest) priority, valid: 0 ~ 1000
    priority = lookup(each.value, "priority", 1000)
    grpc_route {

      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.this[0].name
          weight       = 100
        }
      }
      dynamic match {
        for_each = lookup(each.value, "match", [{
          /*match must be present, even when empty*/
        }])
        content {
          method_name  = lookup(match.value, "method_name", null)
          service_name = lookup(match.value, "service_name", null)
          dynamic metadata {
            for_each = lookup(match.value, "metadata", {})
            content {
              name   = lookup(metadata.value, "name", "missing_name")
              invert = lookup(metadata.value, "invert", false)
              match {
                exact = lookup(metadata.value.match, "exact", null)
                regex = lookup(metadata.value.match, "regex", null)
              }
            }
          }
        }
      }

      timeout {
        idle {
          unit  = "ms"
          value = 5000
        }
        per_request {
          unit  = "s"
          value = 30
        }
      }
      retry_policy {
        max_retries       = 3
        grpc_retry_events = ["cancelled", "unavailable"]
        per_retry_timeout {
          unit  = "ms"
          value = 5000
        }
      }
    }
  }
}

resource "aws_appmesh_route" "http" {
  for_each = lookup(var.app_mesh_configuration, "http_endpoints", {})

  mesh_name           = local.mesh_name
  name                = "${var.service_name}-${each.key}"
  virtual_router_name = var.app_mesh_configuration.virtual_router_name

  spec {
    # 1000 is default (lowest) priority, valid: 0 ~ 1000
    priority = lookup(each.value, "priority", 1000)
    http_route {

      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.this[0].name
          weight       = 100
        }
      }

      dynamic match {
        for_each = lookup(each.value, "match", [{
          /*match must be present, even when empty*/
        }])
        content {
          prefix = lookup(match.value, "prefix", null)
          dynamic header {
            for_each = lookup(match.value, "header", {})
            content {
              name   = lookup(header.value, "name", "missing_name")
              invert = lookup(header.value, "invert", false)
              match {
                exact = lookup(header.value.match, "exact", null)
                regex = lookup(header.value.match, "regex", null)
              }
            }
          }
        }
      }

      timeout {
        idle {
          unit  = "ms"
          value = 5000
        }
        per_request {
          unit  = "s"
          value = 30
        }
      }
      retry_policy {
        max_retries = 3
        # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appmesh_route#http_retry_events
        http_retry_events = ["gateway-error", "server-error"]
        # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appmesh_route#tcp_retry_events
        tcp_retry_events = ["connection-error"]
        per_retry_timeout {
          unit  = "ms"
          value = 5000
        }
      }
    }
  }
}