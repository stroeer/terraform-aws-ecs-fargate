locals {
  ssm_parameters = flatten([
    for container_def in local.container_definitions : (
      lookup(container_def, "secrets", null) != null ? [
        for secret in container_def.secrets : secret.valueFrom
      ] : []
    )
  ])

  ecr_images = {
    for container_def in local.container_definitions : container_def.name => (
      lookup(container_def, "image", null) != null ? container_def.image : null
    )
  }

  ecr_repository_info = [
    for image in values(local.ecr_images) : (
      image != null ? {
        account_id = regex("^([0-9]+)\\.dkr\\.ecr\\.[^/]+\\.amazonaws\\.com/", image)[0]
        region     = regex("^[0-9]+\\.dkr\\.ecr\\.([^.]*)\\.amazonaws\\.com/", image)[0]
        repo_name  = regex("^[0-9]+\\.dkr\\.ecr\\.[^/]+\\.amazonaws\\.com/(.+):.+$", image)[0]
      } : null
    )
  ]
}

resource "aws_iam_role" "task_execution_role" {
  count = var.task_execution_role_arn == "" ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.task_execution_role[count.index].json
  description        = "Task execution role for ${var.service_name}"
  name               = "${var.service_name}-execution-role-${data.aws_region.current.name}"
  path               = "/ecs/"
  tags               = var.tags
}

resource "aws_iam_role_policy" "ssm" {
  count = var.task_execution_role_arn == "" ? 1 : 0

  name   = "ssm-parameter-access-${var.service_name}-${data.aws_region.current.name}"
  role   = var.task_execution_role_arn != "" ? var.task_execution_role_arn : aws_iam_role.task_execution_role[0].id
  policy = data.aws_iam_policy_document.ssm.json
}

data "aws_iam_policy_document" "ssm" {
  statement {
    actions   = ["ssm:GetParameter*", "ssm:DescribeParameters"]
    resources = local.ssm_parameters
  }
}

resource "aws_iam_role_policy" "ecr" {
  count = var.task_execution_role_arn == "" ? 1 : 0

  name   = "ecr-access-${var.service_name}-${data.aws_region.current.name}"
  role   = aws_iam_role.task_execution_role[0].id
  policy = data.aws_iam_policy_document.ecr.json
}


data "aws_iam_policy_document" "ecr" {
  statement {
    sid = "ECRAuthorizationToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PrivateECRRepositoryAccess"
    actions = ["ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
    resources = [
      for repo in local.ecr_repository_info : (
        repo != null ? "arn:aws:ecr:${repo.region}:${repo.account_id}:repository/${repo.repo_name}" : null
      )
    ]
  }

  # https://docs.aws.amazon.com/guardduty/latest/ug/runtime-monitoring-ecr-repository-gdu-agent.html
  statement {
    sid = "GuardDutyAgentECRAccess"
    actions = ["ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
    resources = [
      "arn:aws:ecr:*:*:repository/aws-guardduty-agent-fargate"
    ]
  }
}

resource "aws_iam_role_policy" "logs" {
  count  = var.task_execution_role_arn == "" ? 1 : 0
  name   = "logs-access-${var.service_name}-${data.aws_region.current.name}"
  role   = aws_iam_role.task_execution_role[0].id
  policy = data.aws_iam_policy_document.logs.json
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/${var.service_name}*"
    ]
  }
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
