output "autoscaling_target" {
  description = "ECS auto scaling targets if auto scaling enabled."
  value       = try(aws_appautoscaling_target.ecs[0], null)
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group for container logs."
  value       = try(aws_cloudwatch_log_group.containers[0].name, "")
}

output "container_definitions" {
  description = "Container definitions used by this service including all sidecars."
  sensitive   = true
  value       = local.container_definitions_string
}

output "ecr_repository_arn" {
  description = "Full ARN of the ECR repository."
  value       = join("", module.ecr[*].arn)
}

output "ecr_repository_id" {
  description = "The registry ID where the repository was created."
  value       = join("", module.ecr[*].registry_id)
}

output "ecr_repository_url" {
  description = "The URL of the repository (in the form `aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName`)"
  value       = join("", module.ecr[*].repository_url)
}

output "task_role_arn" {
  description = "ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services."
  value       = try(aws_iam_role.ecs_task_role[0].arn, var.task_role_arn)
}

output "task_role_name" {
  description = "Friendly name of IAM role that allows your Amazon ECS container task to make calls to other AWS services."
  value       = try(aws_iam_role.ecs_task_role[0].name, "")
}

output "task_role_unique_id" {
  description = "Stable and unique string identifying the IAM role that allows your Amazon ECS container task to make calls to other AWS services."
  value       = try(aws_iam_role.ecs_task_role[0].unique_id, "")
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume."
  value       = try(aws_iam_role.task_execution_role[0].arn, var.task_execution_role_arn)
}

output "task_execution_role_name" {
  description = "Friendly name of the task execution role that the Amazon ECS container agent and the Docker daemon can assume."
  value       = try(aws_iam_role.task_execution_role[0].name, "")
}

output "task_execution_role_unique_id" {
  description = "Stable and unique string identifying the IAM role that the Amazon ECS container agent and the Docker daemon can assume."
  value       = try(aws_iam_role.task_execution_role[0].unique_id, "")
}

output "alb_target_group_arns" {
  description = "ARNs of the created target groups."
  value       = aws_alb_target_group.main[*].arn
}

output "alb_target_group_arn_suffixes" {
  description = "ARN suffixes of the created target groups."
  value       = aws_alb_target_group.main[*].arn_suffix
}
