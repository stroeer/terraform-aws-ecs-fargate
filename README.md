Terraform Services module
=========================

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| alb\_listener\_priority | Ordering of listers, must be unique. | `number` | n/a | yes |
| assign\_public\_ip | As Fargate does not support IPv6 yet, this is the only way to enable internet access for the service. | `bool` | `false` | no |
| cluster\_id | The ECS cluster id that should run this service | `string` | n/a | yes |
| container\_definitions | JSON container definition. | `string` | n/a | yes |
| container\_name | Defaults to var.service\_name, can be overriden if it differs. Used as a target for LB. | `string` | `""` | no |
| container\_port | The port used by the web app within the container | `number` | n/a | yes |
| cpu | Amount of CPU required by this service. 1024 == 1 vCPU | `number` | `256` | no |
| desired\_count | Desired count of services to be started/running. | `number` | `0` | no |
| health\_check\_endpoint | Endpoint (/health) that will be probed by the LB to determine the service's health. | `string` | n/a | yes |
| memory | Amount of memory [MB] is required by this service. | `number` | `512` | no |
| policy\_document | AWS Policy JSON describing the permissions required for this service. | `string` | `""` | no |
| service\_name | The service name. Will also be used as Route53 DNS entry. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ecr\_repo\_ids | n/a |

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