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
| create\_log\_streaming | Creates a Kinesis Firehose delivery stream for streaming application logs to an existing Elasticsearch domain. | `bool` | `true` | no |
| desired\_count | Desired count of services to be started/running. | `number` | `0` | no |
| ecr | ECR repository configuration. | <pre>object({<br>    image_scanning_configuration = object({<br>      scan_on_push = bool<br>    })<br>    image_tag_mutability = string,<br>  })</pre> | <pre>{<br>  "image_scanning_configuration": {<br>    "scan_on_push": false<br>  },<br>  "image_tag_mutability": "MUTABLE"<br>}</pre> | no |
| health\_check | A health block containing health check settings for the ALB target groups. See https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#health_check for defaults. | `map(string)` | `{}` | no |
| logs\_domain\_name | The name of an existing Elasticsearch domain used as destination for the Firehose delivery stream. | `string` | `"application-logs"` | no |
| logs\_firehose\_delivery\_stream\_s3\_backup\_bucket\_arn | Use an existing S3 bucket to backup log documents which couldn't be streamed to Elasticsearch. Otherwise a separate bucket for this service will be created. | `string` | `""` | no |
| logs\_fluentbit\_cloudwatch\_log\_group\_name | Use an existing CloudWatch log group for storing logs of the fluent-bit sidecar. Otherwise a dedicate log group for this service will be created. | `string` | `""` | no |
| memory | Amount of memory [MB] is required by this service. | `number` | `512` | no |
| policy\_document | AWS Policy JSON describing the permissions required for this service. | `string` | `""` | no |
| requires\_internet\_access | As Fargate does not support IPv6 yet, this is the only way to enable internet access for the service by placing it in a public subnet (but not assigning a public IP). | `bool` | `false` | no |
| service\_name | The service name. Will also be used as Route53 DNS entry. | `string` | n/a | yes |
| with\_appmesh | This services should be created with an appmesh proxy. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| ecr\_repository\_arn | Full ARN of the ECR repository |
| ecr\_repository\_url | URL of the ECR repository |
| ecs\_task\_exec\_role\_name | ECS task role used by this service. |
| fluentbit\_cloudwatch\_log\_group | Name of the CloudWatch log group of the fluent-bit sidecar. |
| kinesis\_firehose\_delivery\_stream\_name | The name of the Kinesis Firehose delivery stream. |
| private\_dns | Private DNS entry. |
| public\_dns | Public DNS entry. |

