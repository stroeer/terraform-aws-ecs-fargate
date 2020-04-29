# AWS Fargate ECS Terraform Module

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-0.2.0-blue.svg)](https://registry.terraform.io/modules/stroeer/ecs-fargate/aws/0.2.0) ![CI](https://github.com/stroeer/terraform-aws-buzzgate/workflows/CI/badge.svg?branch=master) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://opensource.org/licenses/Apache-2.0)

A somewhat opinionated Terraform module to create Fargate ECS resources on AWS. 

This module supports [automated service deployment](#Automated-service-deployment)
and [log routing](https://docs.amazonaws.cn/en_us/AmazonECS/latest/developerguide/using_firelens.html) to an Elasticsearch domain using 
[Amazon Kinesis Data Firehose delivery streams](https://docs.amazonaws.cn/en_us/AmazonECS/latest/developerguide/using_firelens.html#firelens-example-firehose) and [Fluent-Bit](https://fluentbit.io/).  

## Requirements

The following resources are referenced from this module and therefore prerequisites:

* VPC — There must be a VPC with the following tag: `Name = main`
* Subnets — within this VPC, there must be at least one subnet tagged with `Tier = (public|private)`
* SG (1) — within this VPC there must be a security group `Name = default`
* SG (2) — within this VPC there must be a security group to allow traffic from ALB `Name = fargate-allow-alb-traffic`
* IAM role — There should be a role named `ssm_ecs_task_execution_role` that will be used as a task execution role

### Load Balancing

A service will be attached to a `public` and/or `private` target groups per default. In addition Route53 records will be created for those target groups.Therefore the following resources need to be available:

* ALB — there must be ALBs with `name = (public|private)`. 
* ALB Listeners — Those ALBs should have listeners for HTTP(s) (Port `80` and `443`) configured
* DNS (VPC) — within this VPC there must be a private route53 zone with `name = vpc.internal.`
* DNS (public) — currently there is a hard-coded route53 zone `name = buzz.t-online.delivery.`


In order to disable ALB target group attachments (e.g. for services in an App Mesh) set `alb_attach_public_target_group` and/or `alb_attach_private_target_group` to `false`.

### When using the automated deployment pipeline (optional):

* A shared S3 bucket for storing artifacts from _CodePipeline_ can be used. You can specify
it through the variable `code_pipeline_artifact_bucket`. Otherwise a new bucket is created 
for every service.
* A shared `IAM::Role` for _CodePipeline_ and _CodeBuild_ can be used. You can specify
those through the variables `code_pipeline_role_name` and `code_build_role_name`. Otherwise new 
roles are created for every service. For the permissions required see the [module code](./modules/deployment)
 
## Usage

Simple Fargate ECS service:

```hcl-terraform
locals {
  service_name = "example"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "service" {
  source  = "stroeer/ecs-fargate/aws"
  version = "0.2.0"

  cluster_id                    = "k8"
  container_port                = 8080
  create_log_streaming          = false
  desired_count                 = 1
  service_name                  = local.service_name

  health_check = {
    path = "/health"
  }

  container_definitions         = <<DOC
[
  {
    "name": "${local.service_name}",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.service_name}:production",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [ {"containerPort": 8080, "protocol": "tcp"} ] 
  }
]
DOC
}
``` 

with log streaming to Elasticsearch using Fluent-Bit and Kinesis Firehose Delivery Streams:

```hcl-terraform
locals {
  service_name = "example"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "policy" {  
  statement {
    actions = ["firehose:PutRecordBatch"] 
    resources = ["*"]
  }
}

module "service" {
  source  = "stroeer/ecs-fargate/aws"
  version = "0.2.0"

  cluster_id                    = "k8"s
  container_port                = 8080  
  desired_count                 = 1
  service_name                  = local.service_name

  health_check = {
    path = "/health"
  }

  container_definitions         = <<DOC
[
  {
    "essential": true,
    "image": "906394416424.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/aws-for-fluent-bit:latest",
    "name": "log_router",
    "firelensConfiguration": {
        "type": "fluentbit",
        "options": {
                "config-file-type": "file",
                "config-file-value": "/fluent-bit/configs/parse-json.conf"
        }
    },
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "firelens-container",
            "awslogs-region": "${data.aws_region.current.name}",
            "awslogs-stream-prefix": "firelens"
        }
    },
    "memoryReservation": 50
  },
  {
    "name": "${local.service_name}",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.service_name}:production",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [ {"containerPort": 8080, "protocol": "tcp"} ],
    "logConfiguration": {
      "logDriver": "awsfirelens",
      "options": {
        "Name": "firehose",
        "region": "${data.aws_region.current.name}",
        "delivery_stream": "${module.service.kinesis_firehose_delivery_stream_name}"
      }    
  }
]
DOC
}
```
### Naming Conventions

- Service Names `var.service_name = [a-z-]+`

## Examples

- [public-service](https://github.com/stroeer/terraform-aws-ecs-fargate/tree/master/examples/public-service)

## Documentation

Documentation is generated with `brew install terraform-docs` (see [Makefile](https://github.com/stroeer/terraform-aws-ecs-fargate/blob/master/Makefile)).

## Terraform versions

Only Terraform 0.12+ is supported.

## Release

Release a new module version to the [Terraform registry](https://registry.terraform.io/modules/stroeer/ecs-fargate/aws/) 
(`BUMP` defaults to `patch`):
 
```makefile
make BUMP=(major|minor|patch) release
```

## Automated service deployment

Once `create_deployment_pipeline` is set to `true`, this module will create an automated deployment pipeline:

![deployment pipeline](docs/ecs_deployer.png)

How it works:

- You'll need AWS credentials that allow pushing images into the ECR container registry.
- Once you push an image with `[tag=production]` - a Cloudwatch Event will trigger the start of a CodePipeline
- **⚠ This tag will only trigger the pipeline. You will need a minimum of 3 tags**
1. `production` will trigger the pipeline
2. `container.$CONTAINER_NAME` is required to locate the correct container from the service's [task-definition.json](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html)
3.  One more tag that will be unique and used for the actual deployment and the task-definition.json. A good
choice would be `git.sha`. To be specific, we chose a tag that does not `start with container.` and is none 
of `["local", "production", "staging", "infrastructure"]`

That CodePipeline will do the heavy lifting (see deployment flow above):

1. Pull the full `imagedefinitions.json` from the ECR registry
2. Trigger a CodeBuild to transform the `imagedefinitions.json` into a `imagedefinitions.json` for deployment
3. Update the ECS service's task-definition by replacing the specified `imageUri` for the given `name`.

## Todos

* [ ] Cognito auth for ALB listeners
* [x] CodeDeploy with ECR trigger
* [ ] ECR policies
* [ ] Notification for the deployment pipeline [success/failure] 

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alb\_attach\_private\_target\_group | Attach a target group for this service to the private ALB (requires an ALB with `name=private`). | `bool` | `true` | no |
| alb\_attach\_public\_target\_group | Attach a target group for this service to the public ALB (requires an ALB with `name=public`). | `bool` | `true` | no |
| alb\_cogino\_pool\_arn | Provide a COGNITO pool ARN if you want to attach COGNITO authentication to the public ALB's HTTPS listener. If not set, there will be no auth. | `string` | `null` | no |
| alb\_cogino\_pool\_client\_id | COGNITO client id that will be used for authenticating at the public ALB's HTTPS listener. | `string` | `null` | no |
| alb\_cogino\_pool\_domain | COGNITO pool domain that will be used for authenticating at the public ALB's HTTPS listener. | `string` | `null` | no |
| alb\_listener\_priority | The priority for the ALB listener rule between 1 and 50000. Leaving it unset will automatically set the rule with next available priority after currently existing highest rule. | `number` | `null` | no |
| assign\_public\_ip | As Fargate does not support IPv6 yet, this is the only way to enable internet access for the service. | `bool` | `false` | no |
| cluster\_id | The ECS cluster id that should run this service | `string` | n/a | yes |
| code\_build\_role\_name | Use an existing role for codebuild permissions that can be reused for multiple services. Otherwise a separate role for this service will be created. | `string` | `""` | no |
| code\_pipeline\_artifact\_bucket | Use an existing bucket for codepipeline artifacts that can be reused for multiple services. Otherwise a separate bucket for each service will be created. | `string` | `""` | no |
| code\_pipeline\_role\_name | Use an existing role for codepipeline permissions that can be reused for multiple services. Otherwise a separate role for this service will be created. | `string` | `""` | no |
| container\_definitions | JSON container definition. | `string` | n/a | yes |
| container\_name | Defaults to var.service\_name, can be overriden if it differs. Used as a target for LB. | `string` | `""` | no |
| container\_port | The port used by the web app within the container | `number` | n/a | yes |
| cpu | Amount of CPU required by this service. 1024 == 1 vCPU | `number` | `256` | no |
| create\_deployment\_pipeline | Creates a deploy pipeline from ECR trigger. | `bool` | `true` | no |
| create\_log\_streaming | Creates a Kinesis Firehose delivery stream for streaming application logs to an existing Elasticsearch domain. | `bool` | `true` | no |
| desired\_count | Desired count of services to be started/running. | `number` | `0` | no |
| ecr | ECR repository configuration. | <pre>object({<br>    image_scanning_configuration = object({<br>      scan_on_push = bool<br>    })<br>    image_tag_mutability = string,<br>  })</pre> | <pre>{<br>  "image_scanning_configuration": {<br>    "scan_on_push": false<br>  },<br>  "image_tag_mutability": "MUTABLE"<br>}</pre> | no |
| health\_check | A health block containing health check settings for the ALB target groups. See https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#health_check for defaults. | `map(string)` | `{}` | no |
| logs\_domain\_name | The name of an existing Elasticsearch domain used as destination for the Firehose delivery stream. | `string` | `"application-logs"` | no |
| logs\_firehose\_delivery\_stream\_s3\_backup\_bucket\_arn | Use an existing S3 bucket to backup log documents which couldn't be streamed to Elasticsearch. Otherwise a separate bucket for this service will be created. | `string` | `""` | no |
| logs\_fluentbit\_cloudwatch\_log\_group\_name | Use an existing CloudWatch log group for storing logs of the fluent-bit sidecar. Otherwise a dedicate log group for this service will be created. | `string` | `""` | no |
| memory | Amount of memory [MB] is required by this service. | `number` | `512` | no |
| policy\_document | AWS Policy JSON describing the permissions required for this service. | `string` | `""` | no |
| service\_name | The service name. Will also be used as Route53 DNS entry. | `string` | n/a | yes |
| with\_appmesh | This services should be created with an appmesh proxy. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| ecr\_repository\_arn | Full ARN of the ECR repository |
| ecr\_repository\_url | URL of the ECR repository |
| fluentbit\_cloudwatch\_log\_group | Name of the CloudWatch log group of the fluent-bit sidecar. |
| kinesis\_firehose\_delivery\_stream\_name | The name of the Kinesis Firehose delivery stream. |
| private\_dns | Private DNS entry. |
| public\_dns | Public DNS entry. |

Requirements
------------

Documentation is generated with `brew install terraform-docs`

The following resources are referenced from this module and therefore prerequisites:

* VPC — There must be a VPC with the following tag: `Name = main`
* Subnets — within this VPC, there must be at least one subnet tagged with `Tier = (public|private)`
* SG (1) — within this VPC there must be a security group `Name = default`
* SG (2) — within this VPC there must be a security group to allow traffic from ALB `Name = fargate-allow-alb-traffic`
* DNS (VPC) — within this VPC there must be a private route53 zone with `name = vpc.internal.`
* DNS (public) — currently there is a hard-coded route53 zone `name = buzz.t-online.delivery.`
* ALB — there must be ALBs with `name = (public|private)`. 
* ALB Listeners — Those ALBs should have listeners for HTTP(s) (Port `80` and `443`) configured
* IAM role — There should be a role named `ssm_ecs_task_execution_role` that will be used as a task execution role
* Service discovery namespace `apps.local.` 

### When using the automated deployment pipeline (optional):

* A shared S3 bucket for storing artifacts from _CodePipeline_ can be used. You can specify
it through the variable `code_pipeline_artifact_bucket`. Otherwise a new bucket is created 
for every service.
* A shared `IAM::Role` for _CodePipeline_ and _CodeBuild_ can be used. You can specify
those through the variables `code_pipeline_role_name` and `code_build_role_name`. Otherwise new 
roles are created for every service. For the permissions required see the [module code](./modules/deployment)
 

### Naming Conventions

- Service Names `var.service_name = [a-z-]+`

### Automated Service Deployment

Once `create_deployment_pipeline` is set to `true`, we will create an automated Deployment Pipeline:

![deployment pipeline](docs/ecs_deployer.png)

How it works:

- You'll need AWS credentials that allow pushing images into the ECR container registry.
- Once you push an image with `[tag=production]` - a Cloudwatch Event will trigger the start of a CodePipeline
- **⚠ This tag will only trigger the pipeline. You will need a minimum of 3 tags**
1. `production` will trigger the pipeline
2. `container.$CONTAINER_NAME` is required to locate the correct container from the service's [task-definition.json](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html)
3.  One more tag that will be unique and used for the actual deployment and the task-definition.json. A good
choice would be `git.sha`. To be specific, we chose a tag that does not `start with container.` and is none 
of `["local", "production", "staging", "infrastructure"]`

- That CodePipeline will do the heavy lifting (see deployment flow above):

1. Pull the full `imagedefinitions.json` from the ECR registry
2. Trigger a CodeBuild to transform the `imagedefinitions.json` into a `imagedefinitions.json` for deployment
3. Update the ECS service's task-definition by replacing the specified `imageUri` for the given `name`.
