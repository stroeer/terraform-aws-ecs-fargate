resource "aws_codepipeline" "codepipeline" {
  name     = var.service_name
  role_arn = var.code_pipeline_role == "" ? aws_iam_role.code_pipeline_role[0].arn : data.aws_iam_role.code_pipeline[0].arn

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })

  artifact_store {
    location = var.artifact_bucket == "" ? module.s3_bucket.s3_bucket_id : data.aws_s3_bucket.codepipeline[0].bucket
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
        "ImageTag" : var.ecr_image_tag,
        "RepositoryName" : var.ecr_repository_name
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
      output_artifacts = ["image_definitions_json"]

      configuration = {
        "ProjectName" : aws_codebuild_project.this.name
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
      input_artifacts = ["image_definitions_json"]
      version         = "1"

      configuration = {
        "ClusterName" : var.cluster_name,
        "ServiceName" : var.service_name
        "FileName" : "imagedefinitions.json"
      }
    }
  }
}
