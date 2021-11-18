resource "aws_iam_role" "ecs_task_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
  description        = "ECS Task Role for service ${var.service_name}"
  name               = "${var.service_name}-${data.aws_region.current.name}"
  path               = "/ecs/task-role/"
  tags               = var.tags
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name   = "ecs-task-${var.service_name}-${data.aws_region.current.name}"
  policy = var.policy_document == "" ? data.aws_iam_policy_document.nothing_is_allowed.json : var.policy_document
  role   = aws_iam_role.ecs_task_role.id
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
