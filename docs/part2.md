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

