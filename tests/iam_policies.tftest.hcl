mock_provider "aws" {
  # Stable identities/region used to render image and ARNs
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDAEXAMPLE"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name = "eu-west-1"
    }
  }

  # Avoid lookups failing if referenced; keep minimal outputs
  mock_data "aws_subnets" {
    defaults = {
      ids = ["subnet-aaa", "subnet-bbb"]
    }
  }

  mock_data "aws_lb" {
    defaults = {
      security_groups = ["sg-0123456789abcdef0"]
    }
  }

  mock_data "aws_ecs_task_definition" {
    defaults = {
      family   = "myapp"
      revision = 1
    }
  }

  # Resource mocks to keep plan happy if referenced
  mock_resource "aws_ecs_task_definition" {
    defaults = {
      arn      = "arn:aws:ecs:eu-west-1:123456789012:task-definition/myapp:1"
      family   = "myapp"
      revision = 1
    }
  }
}

variables {
  cluster_id                    = "cl-123"
  container_port                = 8000
  service_name                  = "myapp"
  vpc_id                        = "vpc-123456"
  desired_count                 = 0
  create_ecr_repository         = false
  create_deployment_pipeline    = false
  create_ingress_security_group = false
  cloudwatch_logs = {
    enabled = false
  }
  target_groups = []

  # Add secrets so local.ssm_parameters is populated
  container_definition_overwrites = {
    secrets = [
      {
        name      = "foo"
        valueFrom = "arn:aws:ssm:eu-west-1:123456789012:parameter/myapp/foo"
      },
      {
        name      = "bar"
        valueFrom = "arn:aws:ssm:eu-west-1:123456789012:parameter/myapp/bar"
      }
    ]
  }
}

run "plan_iam_policies" {
  command = plan

  assert {
  condition     = length(aws_iam_role_policy.ecr) > 0 && length(regexall("arn:aws:ecr:eu-west-1:123456789012:repository/myapp", aws_iam_role_policy.ecr[0].policy)) > 0
    error_message = "ECR policy is missing repository ARN for myapp"
  }

  assert {
  condition     = length(aws_iam_role_policy.logs_ssm) > 0 && length(regexall("arn:aws:ssm:eu-west-1:123456789012:parameter/myapp/foo", aws_iam_role_policy.logs_ssm[0].policy)) > 0
    error_message = "logs_ssm policy missing foo SSM parameter ARN"
  }

  assert {
  condition     = length(aws_iam_role_policy.logs_ssm) > 0 && length(regexall("arn:aws:ssm:eu-west-1:123456789012:parameter/myapp/bar", aws_iam_role_policy.logs_ssm[0].policy)) > 0
    error_message = "logs_ssm policy missing bar SSM parameter ARN"
  }
}
