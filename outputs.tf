output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group for container logs."
  value       = aws_cloudwatch_log_group.containers.name
}

output "container_definitions" {
  description = "Container definitions used by this service including all sidecars."
  sensitive   = true
  value       = local.container_definitions
}

output "ecr_repository_arn" {
  description = "Full ARN of the ECR repository."
  value       = join("", module.ecr[*].arn)
}

output "ecr_repository_url" {
  description = "URL of the ECR repository."
  value       = join("", module.ecr[*].repository_url)
}

output "ecs_task_exec_role_arn" {
  description = "The ARN of the ECS task role created for this service."
  value       = try(aws_iam_role.ecs_task_role[0].arn, "")
}

output "ecs_task_exec_role_name" {
  description = "The name of the ECS task role created for this service."
  value       = try(aws_iam_role.ecs_task_role[0].name, "")
}

output "ecs_task_exec_role_unique_id" {
  description = "The unique id of the ECS task role created for this service."
  value       = try(aws_iam_role.ecs_task_role[0].unique_id, "")
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

// TODO: this output should not start with "aws"
output "aws_alb_target_group_arns" {
  description = "ARNs of the created target groups."
  value       = aws_alb_target_group.main[*].arn
}
