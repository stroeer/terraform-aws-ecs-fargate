locals {
  ecr_arn = "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_name}"

  statements = [for ref in var.gh_refs : "repo:${var.gh_repo_name}:ref:refs/heads/${ref}"]
}


resource "aws_iam_role" "ecr_access" {
  name               = "github-ecr-access-${var.ecr_name}-${data.aws_region.current.region}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {

  statement {
    sid     = "GithubOIDCAccess${title(var.ecr_name)}"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.statements
    }

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.id]
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
  description = "Policy providing minimum ECR write permissions."
  policy      = data.aws_iam_policy_document.repo_scoped_ecr_access_permission.json
}

resource "aws_iam_role_policy" "execute_command" {
  name   = "ci-ecr-access"
  policy = data.aws_iam_policy_document.repo_scoped_ecr_access_permission.json
  role   = aws_iam_role.ecr_access.id
}