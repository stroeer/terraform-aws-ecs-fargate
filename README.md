Terraform Services module
=========================

![CI](https://github.com/stroeer/terraform-aws-buzzgate/workflows/CI/badge.svg?branch=master) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://opensource.org/licenses/Apache-2.0)

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| alb\_listener\_priority | Ordering of listeners, must be unique. | `number` | n/a | yes |
| assign\_public\_ip | As Fargate does not support IPv6 yet, this is the only way to enable internet access for the service. | `bool` | `false` | no |
| cluster\_id | The ECS cluster id that should run this service | `string` | n/a | yes |
| code\_build\_role | Use an existing role for codebuild permissions that can be reused for multiple services. | `string` | `""` | no |
| code\_pipeline\_artifact\_bucket | Use an existing bucket for codepipeline artifacts that can be reused for multiple services. | `string` | `""` | no |
| code\_pipeline\_role | Use an existing role for codepipeline permissions that can be reused for multiple services. | `string` | `""` | no |
| container\_definitions | JSON container definition. | `string` | n/a | yes |
| container\_name | Defaults to var.service\_name, can be overriden if it differs. Used as a target for LB. | `string` | `""` | no |
| container\_port | The port used by the web app within the container | `number` | n/a | yes |
| cpu | Amount of CPU required by this service. 1024 == 1 vCPU | `number` | `256` | no |
| create\_deployment\_pipeline | Creates a deploy pipeline from ECR trigger. | `bool` | `true` | no |
| create\_log\_streaming | Creates a Kinesis Firehose delivery stream for streaming application logs to an existing Elasticsearch domain. | `bool` | `true` | no |
| desired\_count | Desired count of services to be started/running. | `number` | `0` | no |
| ecr | ECR repository configuration. | <pre>object({<br>    image_scanning_configuration = object({<br>      scan_on_push = bool<br>    })<br>    image_tag_mutability = string,<br>  })</pre> | <pre>{<br>  "image_scanning_configuration": {<br>    "scan_on_push": false<br>  },<br>  "image_tag_mutability": "MUTABLE"<br>}</pre> | no |
| health\_check\_endpoint | Endpoint (/health) that will be probed by the LB to determine the service's health. | `string` | n/a | yes |
| memory | Amount of memory [MB] is required by this service. | `number` | `512` | no |
| policy\_document | AWS Policy JSON describing the permissions required for this service. | `string` | `""` | no |
| service\_name | The service name. Will also be used as Route53 DNS entry. | `string` | n/a | yes |
| with\_appmesh | This services should be created with an appmesh proxy. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| ecr\_repository\_arn | Full ARN of the ECR repository |
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

Todos
-----

* [ ] Cognito auth for ALB listeners
* [x] CodeDeploy with ECR trigger
* [ ] ECR policies
* [ ] Notification for the deployment pipeline [success/failure] 