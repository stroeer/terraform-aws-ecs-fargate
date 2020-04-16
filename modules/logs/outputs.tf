output "fluentbit_cloudwatch_log_group" {
  description = "Name of the CloudWatch log group of the fluent-bit sidecar."
  value       = var.enabled && var.fluentbit_cloudwatch_log_group_name == "" ? element(aws_cloudwatch_log_group.fluentbit.*.name, 0) : ""
}

output "kinesis_firehose_delivery_stream_name" {
  description = "The name to identify the stream."
  value       = length(aws_kinesis_firehose_delivery_stream.elasticsearch_stream) == 0 ? "" : element(aws_kinesis_firehose_delivery_stream.elasticsearch_stream.*.name, 0)
}
