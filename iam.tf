resource "aws_iam_role" "ecs_task_role" {
  name               = "ecs-${var.service_name}"
  description        = "Role for ECS service ${var.service_name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
  tags               = local.default_tags
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name   = "ecs-${var.service_name}"
  role   = aws_iam_role.ecs_task_role.id
  policy = var.policy_document == "" ? data.aws_iam_policy_document.nothing_is_allowed.json : var.policy_document
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "nothing_is_allowed" {
  statement {
    sid           = "0"
    not_actions   = ["*"]
    not_resources = ["*"]
  }
}

data "aws_iam_role" "task_execution_role" {
  name = "ssm_ecs_task_execution_role"
}
