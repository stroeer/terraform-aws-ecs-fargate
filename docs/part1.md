# AWS Fargate ECS Terraform Module

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-0.1.1-blue.svg)](https://registry.terraform.io/modules/stroeer/ecs-fargate/aws/0.1.1) ![CI](https://github.com/stroeer/terraform-aws-buzzgate/workflows/CI/badge.svg?branch=master) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://opensource.org/licenses/Apache-2.0)

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
  version = "0.1.1"

  alb_listener_priority         = 664  
  cluster_id                    = "k8"
  container_port                = 8080
  create_log_streaming          = false
  desired_count                 = 1
  health_check_endpoint         = "/health"
  service_name                  = local.service_name
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
  version = "0.1.1"

  alb_listener_priority         = 664  
  cluster_id                    = "k8"
  container_port                = 8080  
  desired_count                 = 1
  health_check_endpoint         = "/health"
  service_name                  = local.service_name
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

