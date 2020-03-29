data "aws_s3_bucket" "this" {
  bucket = "codepipeline-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

data "aws_iam_role" "codepipeline" {
  name = "codepipeline_role"
}

resource "aws_codepipeline" "codepipeline" {
  count    = var.create_deployment_pipeline ? 1 : 0
  name     = var.service_name
  role_arn = data.aws_iam_role.codepipeline.arn
  tags     = var.tags

  artifact_store {
    location = data.aws_s3_bucket.this.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "ECR"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["ecr_source"]

      configuration = {
        "ImageTag": "production",
        "RepositoryName": var.ecr_repository_name
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["ecr_source"]
      output_artifacts = ["build_source"]

      configuration = {
        "ProjectName": aws_codebuild_project.this[count.index].name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_source"]
      version         = "1"

      configuration = {
        "ClusterName": "k8",
        "ServiceName": var.service_name
        "FileName": "imagedefinitions.json"
      }
    }
  }

  depends_on = [
    aws_codebuild_project.this
  ]
}
