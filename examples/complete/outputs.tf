output "endpoint" {
  value = "http://${module.alb.dns_name}/"
}
