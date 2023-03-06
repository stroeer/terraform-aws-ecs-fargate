data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy" "ecs_task_execution_policy" {
  count = var.task_execution_role_arn == "" ? 1 : 0

  name = "AmazonECSTaskExecutionRolePolicy"
}
