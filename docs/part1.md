# AWS Fargate ECS Terraform Module

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-0.14.1-blue.svg)](https://registry.terraform.io/modules/stroeer/ecs-fargate/aws/0.14.1) ![CI](https://github.com/stroeer/terraform-aws-buzzgate/workflows/CI/badge.svg?branch=master) ![Terraform Version](https://img.shields.io/badge/Terraform-0.12+-green.svg) [![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://opensource.org/licenses/Apache-2.0)

A somewhat opinionated Terraform module to create Fargate ECS resources on AWS.

This module does the heavy lifting for:

* [ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html) configuration
* [automated service deployment](#Automated-service-deployment) including notifications
* CloudWatch log group and IAM permissions for storing container logs (e.g. for sidecars)
* integration with [App Mesh](https://docs.aws.amazon.com/app-mesh/latest/userguide/what-is-app-mesh.html)
  and [Application Load Balancers](#Load-Balancing)

## Requirements

The following resources are referenced from this module and therefore prerequisites:

* Subnets — within this VPC, there must be at least one subnet tagged with either `Tier = (public|private)`. The
  fargate _Elastic Network Interface_ will be placed here.
* SG (1) — within this VPC there must be a security group `Name = default`
* SG (2) — within this VPC there must be a security group to allow traffic from ALB `Name = fargate-allow-alb-traffic`
* IAM role — There should be a role named `ssm_ecs_task_execution_role` that will be used as a task execution role

### Load Balancing

`
A service can be attached to a ALB. Neither the ALB nor the Listeners are created by the module (see example app).

Sample for an service running a `HTTP` service on port `80`:

```terraform
module "service" {
  source = "..."

  target_groups = [
    {
      name             = "${local.service_name}-public"
      backend_port     = 80
      backend_protocol = "HTTP"
      target_type      = "ip"
      health_check     = {
        enabled = true
        path    = "/"
      }
    }
  ]

  https_listener_rules = [{
    listener_arn = aws_lb_listener.http.arn

    priority   = 42
    actions    = [{
      type               = "forward"
      target_group_index = 0
    }]
    conditions = [{
      path_patterns = ["/"]
      host_headers  = ["www.example.com"]
    }]
  }]
}
```

### DNS / Route53

DNS is also not part of this module and needs to be provided by the caller:

```terraform
resource "aws_route53_record" "this" {
  name    = "..."
  type    = "..."
  zone_id = "..."
}
```

this should point to your ALB. If TLS/HTTPS will be used an ACM certificate is also required.

In order to disable ALB target group attachments (e.g. for services in an App Mesh) set `target_groups = []`.

### When using the automated deployment pipeline (optional):

* A shared S3 bucket for storing artifacts from _CodePipeline_ can be used. You can specify it through the
  variable `code_pipeline_artifact_bucket`. Otherwise a new bucket is created for every service.
* A shared `IAM::Role` for _CodePipeline_ and _CodeBuild_ can be used. You can specify those through the
  variables `code_pipeline_role_name` and `code_build_role_name`. Otherwise new roles are created for every service. For
  the permissions required see the [module code](./modules/deployment)

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
  version = "0.14.1"

  assign_public_ip           = true
  cluster_id                 = aws_ecs_cluster.main.id
  container_port             = 80
  create_deployment_pipeline = false
  desired_count              = 1
  service_name               = local.service_name
  vpc_id                     = module.vpc.vpc_id

  target_groups = [
    {
      name             = "${local.service_name}-public"
      backend_port     = 80
      backend_protocol = "HTTP"
      target_type      = "ip"
      health_check     = {
        enabled = true
        path    = "/"
      }
    }
  ]

  https_listener_rules = [{
    listener_arn = aws_lb_listener.http.arn

    priority   = 42
    actions    = [{
      type               = "forward"
      target_group_index = 0
    }]
    conditions = [{
      path_patterns = ["/"]
    }]
  }]

  container_definitions = jsonencode([
    {
      command: [
        "/bin/sh -c \"echo '<html> <head> <title>Hello from httpd service</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
      ],
      cpu: 256,
      entryPoint: ["sh", "-c"],
      essential: true,
      image: "httpd:2.4",
      memory: 512,
      name: local.service_name,
      portMappings: [{
        containerPort: 80
        hostPort: 80
        protocol: "tcp"
      }]
    }
  ])

  ecr = {
    image_tag_mutability         = "IMMUTABLE"
    image_scanning_configuration = {
      scan_on_push = true
    }
  }
}
```

### Naming Conventions

- Service Names `var.service_name = [a-z-]+`

## Examples

- [public-service](https://github.com/stroeer/terraform-aws-ecs-fargate/tree/master/examples/public-service)

## Documentation

Documentation is generated with `brew install terraform-docs` (
see [Makefile](https://github.com/stroeer/terraform-aws-ecs-fargate/blob/master/Makefile)).

## Terraform versions

Only Terraform 0.12+ is supported.

## Release

Release a new module version to the [Terraform registry](https://registry.terraform.io/modules/stroeer/ecs-fargate/aws/)
(`BUMP` defaults to `patch`):

```makefile
make BUMP=(major|minor|patch) release
```

## Automated Service Deployment

Once `create_deployment_pipeline` is set to `true`, we will create an automated Deployment Pipeline:

![deployment pipeline](docs/ecs_deployer.png)

**How it works**

- You'll need AWS credentials that allow pushing images into the ECR container registry.
- Once you push an image with `[tag=production]` - a Cloudwatch Event will trigger the start of a CodePipeline
- **⚠ This tag will only trigger the pipeline. You will need a minimum of 3 tags**

1. `production` will trigger the pipeline
2. `container.$CONTAINER_NAME` is required to locate the correct container from the
   service's [task-definition.json](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html)
3. One more tag that will be unique and used for the actual deployment and the task-definition.json. A good choice would
   be `git.sha`. To be specific, we chose a tag that does not `start with container.` and is none
   of `["local", "production", "staging", "infrastructure"]`

**That CodePipeline will do the heavy lifting (see deployment flow above)**

1. Pull the full `imagedefinitions.json` from the ECR registry
2. Trigger a CodeBuild to transform the `imagedefinitions.json` into a `imagedefinitions.json` for deployment
3. Update the ECS service's task-definition by replacing the specified `imageUri` for the given `name`.

**Notifications**

We will create a notification rule for the pipeline. You can provide your ARN of a notification rule target (e.g. a SNS
topic ARN) using
`codestar_notifications_target_arn`. Otherwise a new SNS topic with required permissions is created for every service.
See
[aws_codestarnotifications_notification_rule](https://www.terraform.io/docs/providers/aws/r/codestarnotifications_notification_rule.html)
for details.

You can then configure an integration between those notifications
and [AWS Chatbot](https://docs.aws.amazon.com/dtconsole/latest/userguide/notifications-chatbot.html)
for example.

## Todos

* [x] Cognito auth for ALB listeners
* [x] CodeDeploy with ECR trigger
* [ ] ECR policies
* [x] Notification for the deployment pipeline [success/failure] 

