output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group for container logs"
  value       = module.logs.cloudwatch_log_group_name
}

output "ecr_repository_arn" {
  description = "Full ARN of the ECR repository"
  value       = module.ecr.arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecs_task_exec_role_name" {
  description = "ECS task role used by this service."
  value       = aws_iam_role.ecs_task_role.name
}
