# Code Deploy: IAM Role
# https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-service-role.html
resource "aws_iam_role" "code_deploy_role" {
  count              = var.use_code_deploy ? 1 : 0
  name               = "code_deploy_role"
  description        = " Provides CodeDeploy service wide access to perform an ECS blue/green deployment on your behalf. Grants full access to support services, such as full access to read all S3 objects, invoke all Lambda functions, publish to all SNS topics within the account and update all ECS services. "
  assume_role_policy = data.aws_iam_policy_document.allow_code_deploy_role.json
  #  tags               = module.tags.default_tags
}

data "aws_iam_policy_document" "allow_code_deploy_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS" {
  count      = var.use_code_deploy ? 1 : 0
  role       = aws_iam_role.code_deploy_role[count.index].name
  policy_arn = data.aws_iam_policy.AWSCodeDeployRoleForECS.arn
}

data "aws_iam_policy" "AWSCodeDeployRoleForECS" {
  arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_iam_policy" "code_deploy_extra" {
  count       = var.use_code_deploy ? 1 : 0
  name        = "tf-code-deploy-extras"
  description = "tf-code-deploy-extras"
  policy      = data.aws_iam_policy_document.code_deploy_extra.json
}

resource "aws_iam_role_policy_attachment" "code_deploy_extra" {
  count            = var.use_code_deploy ? 1 : 0
  role       = aws_iam_role.code_deploy_role[count.index].name
  policy_arn = aws_iam_policy.code_deploy_extra[count.index].arn
}

data "aws_iam_policy_document" "code_deploy_extra" {
  statement {
    actions   = ["ecs:*"]
    resources = ["*"]
  }
}