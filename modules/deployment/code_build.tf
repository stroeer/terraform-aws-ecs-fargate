data "aws_iam_role" "codebuild" {
  name = "codebuild_role"
}

resource "aws_codebuild_project" "this" {
  count        = var.enabled ? 1 : 0
  name         = "${var.service_name}-deployment"
  service_role = data.aws_iam_role.codebuild.arn
  tags         = var.tags

  artifacts {
    type                = "CODEPIPELINE"
    artifact_identifier = "deploy_output"
    location            = "imagedefinitions.json"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:1.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.7
  build:
    commands:
      - |
        cat imageDetail.json | python -c 'import sys, json

        imgDetail = json.load(sys.stdin)

        repo_uri = imgDetail["ImageURI"].split("@")[0]
        all_tags = imgDetail["ImageTags"]

        container_tag = [x for x in all_tags if x.startswith("container.")]
        if container_tag:
            container = container_tag[0].split(".")[1]
        else:
            print("Could not extract container from tags {}. Expected one tag with \"container.CONTAINER_NAME\".".format(all_tags), file=sys.stderr)
            exit(1)

        deploy_tag = [x for x in all_tags if not x.startswith("container.") and x not in ["local", "production", "staging", "infrastructure"]]
        if deploy_tag:
            tag = deploy_tag[0]
        else:
            tag = all_tags[0]

        print("""[{{"name":"{}","imageUri":"{}:{}"}}]""".format(container, repo_uri, tag))' > imagedefinitions.json
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
