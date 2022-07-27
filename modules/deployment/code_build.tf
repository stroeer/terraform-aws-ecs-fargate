resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/codebuild/${var.service_name}-deployment"
  retention_in_days = 7

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })
}

resource "aws_codebuild_project" "this" {
  name         = "${var.service_name}-deployment"
  service_role = var.code_build_role == "" ? aws_iam_role.code_build_role[0].arn : data.aws_iam_role.code_build[0].arn

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })

  artifacts {
    type                = "CODEPIPELINE"
    artifact_identifier = "deploy_output"
    location            = "imagedefinitions.json"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.this.name
      status     = "ENABLED"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.8
  build:
    commands:
      - |
        python -c 'import json, os
        with open("imageDetail.json", "r") as json_file:
            image_uri = json.load(json_file).get("ImageURI")
            container_name = os.environ.get("CONTAINER_NAME")
            with open("imagedefinitions.json", "w") as outfile:
                json.dump([{"name": container_name, "imageUri": image_uri}], outfile)'

      - cat imagedefinitions.json
artifacts:
    files:
      - imagedefinitions.json
EOF
  }
}

/* Sample Input imageDetail.json
{
    "ImageSizeInBytes": "50801513",
    "ImageDigest": "sha256:c3f76d75ee2150c7732b2b9c563234563550855c9f25f35cdd6754114c180cf9",
    "Version": "1.0",
    "ImagePushedAt": "Thu Oct 31 13:19:48 UTC 2019",
    "RegistryId": "933782373565",
    "RepositoryName": "code-deploy-sample",
    "ImageURI": "933782373565.dkr.ecr.eu-west-1.amazonaws.com/code-deploy-sample@sha256:c3f76d75ee2150c7732b2b9c563234563550855c9f25f35cdd6754114c180cf9",
    "ImageTags": [
        "production",
        "build_2",
        "container.code-deploy-sample"
    ]
}
*/

/* Sample output imagedefinitions.json https://docs.aws.amazon.com/codepipeline/latest/userguide/file-reference.html

[
  {
    "name": "sample-app",
    "imageUri": "11111EXAMPLE.dkr.ecr.us-west-2.amazonaws.com/ecs-repo:latest"
  }
]

*/
