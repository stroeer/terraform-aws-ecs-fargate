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

Todos
-----

* [ ] Cognito auth for ALB listeners
* [ ] CodeDeploy with ECR trigger
* [ ] ECR policies