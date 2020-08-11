output "fluentbit_cloudwatch_log_group" {
  description = "Name of the CloudWatch log group of the fluent-bit sidecar."
  value       = var.elasticsearch_domain_arn != "" && var.fluentbit_cloudwatch_log_group_name == "" ? element(aws_cloudwatch_log_group.fluentbit.*.name, 0) : ""
}
