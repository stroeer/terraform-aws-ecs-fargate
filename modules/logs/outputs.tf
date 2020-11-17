output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for container logs"
  value       = aws_cloudwatch_log_group.containers.name
}
