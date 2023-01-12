resource "aws_iam_role" "ecs_task_role" {
  count = var.task_role_arn == "" ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy[count.index].json
  description        = "ECS Task Role for service ${var.service_name}"
  name               = "${var.service_name}-${data.aws_region.current.name}"
  path               = "/ecs/task-role/"
  tags               = var.tags
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  count = var.task_role_arn == "" ? 1 : 0

  name   = "ecs-task-${var.service_name}-${data.aws_region.current.name}"
  policy = var.policy_document == "" ? data.aws_iam_policy_document.nothing_is_allowed[count.index].json : var.policy_document
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

data "aws_iam_policy_document" "nothing_is_allowed" {
  count = var.task_role_arn == "" ? 1 : 0

  statement {
    sid           = "0"
    not_actions   = ["*"]
    not_resources = ["*"]
  }
}
