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

Todos
-----

* [ ] Cognito auth for ALB listeners
* [x] CodeDeploy with ECR trigger
* [ ] ECR policies
* [ ] Notification for the deployment pipeline [success/failure] 