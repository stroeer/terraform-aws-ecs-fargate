// todo -> this must be global for all projects
resource "aws_s3_bucket" "codepipeline_bucket" {
  count         = var.use_code_deploy ? 1 : 0
  bucket        = "codepipeline-bucket-mana-stroeer"
  acl           = "private"
  force_destroy = true
}

resource "aws_codepipeline" "codepipeline" {
  count    = var.use_code_deploy ? 1 : 0
  name     = var.service_name
  role_arn = aws_iam_role.code_pipeline_role[count.index].arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket[count.index].bucket
    type     = "S3"

    //    encryption_key {
    //      id   = data.aws_kms_alias.s3kmskey.arn
    //      type = "KMS"
    //    }
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
        "RepositoryName": var.service_name
      }
    }

    action {
      name             = "GIT"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["git_source"]

      configuration = {
        "Owner": "thisismana",
        "Repo": "code-deploy-sample"
        "PollForSourceChanges": "false",
        "Branch": "master"
        "OAuthToken": "cb522a63c2c0ee3132f8affb79aa0a388babf454"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["git_source", "ecr_source"]
      version         = "1"

      configuration = {
        "ApplicationName": aws_codedeploy_app.this[0].name,
        "DeploymentGroupName": aws_codedeploy_deployment_group.example[count.index].deployment_group_name,
        "Image1ArtifactName": "ecr_source",
        "Image1ContainerName": "IMAGE1_NAME",
        "TaskDefinitionTemplateArtifact": "git_source",
        "TaskDefinitionTemplatePath": "taskdef.json",
        "AppSpecTemplateArtifact": "git_source",
        "AppSpecTemplatePath": "appspec.yaml",
      }
    }
  }

  //  stage {
  //    name = "Deploy"
  //
  //    action {
  //      name            = "Deploy"
  //      category        = "Deploy"
  //      owner           = "AWS"
  //      provider        = "ECS"
  //      input_artifacts = ["git_source"]
  //      version         = "1"
  //
  //      configuration = {
  //        "ClusterName": data.terraform_remote_state.ecs_cluster.outputs.ecs_cluster_name,
  //        "ServiceName": var.container_name
  //        # "FileName": "imagedefinitions.json"
  //      }
  //    }
  //  }
}