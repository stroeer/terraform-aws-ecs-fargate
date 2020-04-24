output "ecr_repository_arn" {
  description = "Full ARN of the ECR repository"
  value       = module.ecr.arn
}

output "fluentbit_cloudwatch_log_group" {
  description = "Name of the CloudWatch log group of the fluent-bit sidecar."
  value       = module.logs.fluentbit_cloudwatch_log_group
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "kinesis_firehose_delivery_stream_name" {
  description = "The name of the Kinesis Firehose delivery stream."
  value       = module.logs.kinesis_firehose_delivery_stream_name
}

output "private_dns" {
  description = "Private DNS entry."
  value       = "${aws_route53_record.internal.name}.${data.aws_route53_zone.internal.name}"
}

output "public_dns" {
  description = "Public DNS entry."
  value       = "${aws_route53_record.external.name}.${data.aws_route53_zone.external.name}"
}
