resource "aws_iam_role" "task_execution_role" {
  count = var.task_execution_role_arn == "" ? 1 : 0

  assume_role_policy  = data.aws_iam_policy_document.task_execution_role[count.index].json
  description         = "Task execution role for ${var.service_name}"
  name                = "${var.service_name}-execution-role-${data.aws_region.current.name}"
  managed_policy_arns = [data.aws_iam_policy.ecs_task_execution_policy[count.index].arn]
  path                = "/ecs/"
  tags                = var.tags
}

data "aws_iam_policy_document" "task_execution_role" {
  count = var.task_execution_role_arn == "" ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  count = var.task_role_arn == "" ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy[count.index].json
  description        = "Task Role for service ${var.service_name}"
  name               = "${var.service_name}-${data.aws_region.current.name}"
  path               = "/ecs/task-role/"
  tags               = var.tags
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  count = var.task_role_arn == "" && var.policy_document != "" ? 1 : 0

  name   = "ecs-task-${var.service_name}-${data.aws_region.current.name}"
  policy = var.policy_document
  role   = aws_iam_role.ecs_task_role[count.index].id
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  count = var.task_role_arn == "" ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "enable_execute_command" {
  count = var.enable_execute_command && var.task_role_arn == "" ? 1 : 0

  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "enable_execute_command" {
  count = var.enable_execute_command ? 1 : 0

  name   = "enable-execute-command-${var.service_name}-${data.aws_region.current.name}"
  path   = "/ecs/task-role/"
  policy = data.aws_iam_policy_document.enable_execute_command[count.index].json
}

resource "aws_iam_role_policy_attachment" "enable_execute_command" {
  count = var.enable_execute_command && var.task_role_arn == "" ? 1 : 0

  role       = aws_iam_role.ecs_task_role[count.index].name
  policy_arn = aws_iam_policy.enable_execute_command[count.index].arn
}
