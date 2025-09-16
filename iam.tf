locals {
  ecr_name = var.create_ecr_repository ? module.ecr[0].name : var.ecr_repository_name
  ecr_arn  = var.create_ecr_repository ? module.ecr[0].arn : "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"

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
  name               = "${var.service_name}-execution-role-${data.aws_region.current.region}"
  path               = "/ecs/"
  tags               = var.tags
}

resource "aws_iam_role_policy" "ecr" {
  count = var.task_execution_role_arn == "" ? 1 : 0

  name   = "ecr-policy"
  role   = aws_iam_role.task_execution_role[count.index].id
  policy = data.aws_iam_policy_document.ecr.json
}

data "aws_iam_policy_document" "ecr" {
  statement {
    sid       = "ECRAuthorizationToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid     = "PrivateECRRepositoryAccess"
    actions = ["ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
    resources = compact([
      for repo in local.ecr_repository_info : (
        repo != null ? "arn:aws:ecr:${repo.region}:${repo.account_id}:repository/${repo.repo_name}" : null
      )
    ])
  }

  # https://docs.aws.amazon.com/guardduty/latest/ug/runtime-monitoring-ecr-repository-gdu-agent.html
  statement {
    sid     = "GuardDutyAgentECRAccess"
    actions = ["ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
    resources = [
      "arn:aws:ecr:*:*:repository/aws-guardduty-agent-fargate"
    ]
  }
}

resource "aws_iam_role_policy" "logs_ssm" {
  count = var.task_execution_role_arn == "" ? 1 : 0

  name   = "logs-and-ssm-policy"
  role   = aws_iam_role.task_execution_role[count.index].id
  policy = data.aws_iam_policy_document.logs_ssm.json
}

data "aws_iam_policy_document" "logs_ssm" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/${var.service_name}*"
    ]
  }

  dynamic "statement" {
    for_each = length(local.ssm_parameters) > 0 ? [true] : []

    content {
      actions   = ["ssm:GetParameter*", "ssm:DescribeParameters"]
      resources = local.ssm_parameters
    }
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
  name               = "${var.service_name}-${data.aws_region.current.region}"
  path               = "/ecs/task-role/"
  tags               = var.tags
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  count = var.task_role_arn == "" && var.policy_document != "" ? 1 : 0

  name   = "ecs-task-${var.service_name}-${data.aws_region.current.region}"
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

resource "aws_iam_role_policy" "execute_command" {
  count = var.enable_execute_command && var.task_role_arn == "" ? 1 : 0

  name   = "execute-command-policy"
  policy = data.aws_iam_policy_document.enable_execute_command[count.index].json
  role   = aws_iam_role.ecs_task_role[count.index].id
}

resource "aws_iam_role" "ecr_access" {
  count = length(data.aws_iam_policy_document.assume_role_policy)

  name               = "github-ecr-access-${local.ecr_name}-${count.index}-${data.aws_region.current.region}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[count.index].json
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = var.aws_iam_openid_connect_provider == "" ? 0 : 1

  dynamic "statement" {
    for_each = var.ecr_statements
    content {
      sid     = "GithubOIDCAccess${title(local.ecr_name)}"
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      condition {
        // StringEquals => exact match, no wildcards
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:sub"
        values   = [statement.value]
      }

      principals {
        type        = "Federated"
        identifiers = [var.aws_iam_openid_connect_provider]
      }
    }

  }
}

data "aws_iam_policy_document" "repo_scoped_ecr_access_permission" {

  statement {
    sid    = "AllowRepoScopedUploadECR"
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [
      local.ecr_arn
    ]
  }

  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_policy" {
  count = length(data.aws_iam_policy_document.assume_role_policy)

  description = "Policy providing minimum ECR write permissions."
  policy      = data.aws_iam_policy_document.repo_scoped_ecr_access_permission.json
}

resource "aws_iam_policy_attachment" "ecr" {
  count = length(data.aws_iam_policy_document.assume_role_policy)

  roles      = [aws_iam_role.ecr_access[count.index].name]
  policy_arn = aws_iam_policy.ecr_policy[count.index].arn
  name       = "ci-ecr-access-${local.ecr_name}-${data.aws_region.current.region}"
}
