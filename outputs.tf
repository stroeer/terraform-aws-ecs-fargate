output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group for container logs."
  value       = aws_cloudwatch_log_group.containers.name
}

output "ecr_repository_arn" {
  description = "Full ARN of the ECR repository."
  value       = join("", module.ecr[*].arn)
}

output "ecr_repository_url" {
  description = "URL of the ECR repository."
  value       = join("", module.ecr[*].repository_url)
}

output "ecs_task_exec_role_name" {
  description = "ECS task role used by this service."
  value       = aws_iam_role.ecs_task_role.name
}

output "autoscaling_target" {
  description = "ECS auto scaling targets if auto scaling enabled."
  value       = try(aws_appautoscaling_target.ecs[0], null)
}

// TODO: remove this intermediate output
output "target_group_arns" {
  description = "ARNs of the created target groups."
  value       = aws_alb_target_group.main[*].arn
}

output "aws_alb_target_group_arns" {
  description = "ARNs of the created target groups."
  value       = aws_alb_target_group.main[*].arn
}
