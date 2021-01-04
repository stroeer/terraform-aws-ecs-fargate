## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.17 |
| aws | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0 |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alb\_attach\_private\_target\_group | Attach a target group for this service to the private ALB (requires an ALB with `name=private`). | `bool` | `true` | no |
| alb\_attach\_public\_target\_group | Attach a target group for this service to the public ALB (requires an ALB with `name=public`). | `bool` | `true` | no |
| alb\_cogino\_pool\_arn | Provide a COGNITO pool ARN if you want to attach COGNITO authentication to the public ALB's HTTPS listener. If not set, there will be no auth. | `string` | `""` | no |
| alb\_cogino\_pool\_client\_id | COGNITO client id that will be used for authenticating at the public ALB's HTTPS listener. | `string` | `""` | no |
| alb\_cogino\_pool\_domain | COGNITO pool domain that will be used for authenticating at the public ALB's HTTPS listener. | `string` | `""` | no |
| alb\_listener\_priority | The priority for the ALB listener rule between 1 and 50000. Leaving it unset will automatically set the rule with next available priority after currently existing highest rule. | `number` | `null` | no |
| assign\_public\_ip | This services will be placed in a public subnet and be assigned a public routable IP. | `bool` | `false` | no |
| cluster\_id | The ECS cluster id that should run this service | `string` | n/a | yes |
| code\_build\_role\_name | Use an existing role for codebuild permissions that can be reused for multiple services. Otherwise a separate role for this service will be created. | `string` | `""` | no |
| code\_pipeline\_artifact\_bucket | Use an existing bucket for codepipeline artifacts that can be reused for multiple services. Otherwise a separate bucket for each service will be created. | `string` | `""` | no |
| code\_pipeline\_role\_name | Use an existing role for codepipeline permissions that can be reused for multiple services. Otherwise a separate role for this service will be created. | `string` | `""` | no |
| codestar\_notifications\_detail\_type | The level of detail to include in the notifications for this resource. Possible values are BASIC and FULL. | `string` | `"BASIC"` | no |
| codestar\_notifications\_event\_type\_ids | A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api. | `list(string)` | <pre>[<br>  "codepipeline-pipeline-pipeline-execution-succeeded",<br>  "codepipeline-pipeline-pipeline-execution-failed"<br>]</pre> | no |
| codestar\_notifications\_target\_arn | Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created. | `string` | `""` | no |
| container\_definitions | JSON container definition. | `string` | n/a | yes |
| container\_name | Defaults to var.service\_name, can be overriden if it differs. Used as a target for LB. | `string` | `""` | no |
| container\_port | The port used by the web app within the container | `number` | n/a | yes |
| cpu | Amount of CPU required by this service. 1024 == 1 vCPU | `number` | `256` | no |
| create\_deployment\_pipeline | Creates a deploy pipeline from ECR trigger. | `bool` | `true` | no |
| desired\_count | Desired count of services to be started/running. | `number` | `0` | no |
| ecr | ECR repository configuration. | <pre>object({<br>    image_scanning_configuration = object({<br>      scan_on_push = bool<br>    })<br>    image_tag_mutability = string,<br>  })</pre> | <pre>{<br>  "image_scanning_configuration": {<br>    "scan_on_push": true<br>  },<br>  "image_tag_mutability": "MUTABLE"<br>}</pre> | no |
| force\_new\_deployment | Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g. myimage:latest), roll Fargate tasks onto a newer platform version, or immediately deploy ordered\_placement\_strategy and placement\_constraints updates. | `bool` | `false` | no |
| health\_check | A health block containing health check settings for the ALB target groups. See https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#health_check for defaults. | `map(string)` | `{}` | no |
| logs\_elasticsearch\_domain\_arn | Amazon Resource Name (ARN) of an existing Elasticsearch domain. IAM permissions for sending logs to this domain will be added. | `string` | `""` | no |
| memory | Amount of memory [MB] is required by this service. | `number` | `512` | no |
| platform\_version | The platform version on which to run your service. Defaults to LATEST. | `string` | `"LATEST"` | no |
| policy\_document | AWS Policy JSON describing the permissions required for this service. | `string` | `""` | no |
| requires\_internet\_access | As Fargate does not support IPv6 yet, this is the only way to enable internet access for the service by placing it in a public subnet (but not assigning a public IP). | `bool` | `false` | no |
| service\_name | The service name. Will also be used as Route53 DNS entry. | `string` | n/a | yes |
| tags | Additional tags (\_e.g.\_ { map-migrated : d-example-443255fsf }) | `map(string)` | `{}` | no |
| with\_appmesh | This services should be created with an appmesh proxy. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudwatch\_log\_group | Name of the CloudWatch log group for container logs |
| ecr\_repository\_arn | Full ARN of the ECR repository |
| ecr\_repository\_url | URL of the ECR repository |
| ecs\_task\_exec\_role\_name | ECS task role used by this service. |
| private\_dns | Private DNS entry. |
| public\_dns | Public DNS entry. |

