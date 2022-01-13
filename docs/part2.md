## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.17 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.71.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_code_deploy"></a> [code\_deploy](#module\_code\_deploy) | ./modules/deployment | n/a |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ./modules/ecr | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_alb_listener_rule.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_listener_rule) | resource |
| [aws_alb_target_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_target_group) | resource |
| [aws_appautoscaling_policy.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.containers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.cloudwatch_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_task_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_service_discovery_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_definition) | data source |
| [aws_iam_policy_document.cloudwatch_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_task_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.nothing_is_allowed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_security_group.fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnet_ids.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) | data source |
| [terraform_remote_state.ecs](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_appautoscaling_settings"></a> [appautoscaling\_settings](#input\_appautoscaling\_settings) | Autoscaling configuration for this service. | `map(any)` | `null` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | This services will be placed in a public subnet and be assigned a public routable IP. | `bool` | `false` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ECS cluster id that should run this service | `string` | n/a | yes |
| <a name="input_code_build_role_name"></a> [code\_build\_role\_name](#input\_code\_build\_role\_name) | Use an existing role for codebuild permissions that can be reused for multiple services. Otherwise a separate role for this service will be created. | `string` | `""` | no |
| <a name="input_code_pipeline_artifact_bucket"></a> [code\_pipeline\_artifact\_bucket](#input\_code\_pipeline\_artifact\_bucket) | Use an existing bucket for codepipeline artifacts that can be reused for multiple services. Otherwise a separate bucket for each service will be created. | `string` | `""` | no |
| <a name="input_code_pipeline_artifact_bucket_sse"></a> [code\_pipeline\_artifact\_bucket\_sse](#input\_code\_pipeline\_artifact\_bucket\_sse) | AWS KMS master key id for server-side encryption. | `any` | `{}` | no |
| <a name="input_code_pipeline_role_name"></a> [code\_pipeline\_role\_name](#input\_code\_pipeline\_role\_name) | Use an existing role for codepipeline permissions that can be reused for multiple services. Otherwise a separate role for this service will be created. | `string` | `""` | no |
| <a name="input_codestar_notifications_detail_type"></a> [codestar\_notifications\_detail\_type](#input\_codestar\_notifications\_detail\_type) | The level of detail to include in the notifications for this resource. Possible values are BASIC and FULL. | `string` | `"BASIC"` | no |
| <a name="input_codestar_notifications_event_type_ids"></a> [codestar\_notifications\_event\_type\_ids](#input\_codestar\_notifications\_event\_type\_ids) | A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api. | `list(string)` | <pre>[<br>  "codepipeline-pipeline-pipeline-execution-succeeded",<br>  "codepipeline-pipeline-pipeline-execution-failed"<br>]</pre> | no |
| <a name="input_codestar_notifications_kms_master_key_id"></a> [codestar\_notifications\_kms\_master\_key\_id](#input\_codestar\_notifications\_kms\_master\_key\_id) | AWS KMS master key id for server-side encryption. | `string` | `null` | no |
| <a name="input_codestar_notifications_target_arn"></a> [codestar\_notifications\_target\_arn](#input\_codestar\_notifications\_target\_arn) | Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created. | `string` | `""` | no |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | JSON container definition. | `string` | n/a | yes |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Defaults to var.service\_name, can be overridden if it differs. Used as a target for LB. | `string` | `""` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port used by the web app within the container | `number` | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Amount of CPU required by this service. 1024 == 1 vCPU | `number` | `256` | no |
| <a name="input_create_deployment_pipeline"></a> [create\_deployment\_pipeline](#input\_create\_deployment\_pipeline) | Creates a deploy pipeline from ECR trigger. | `bool` | `true` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Desired count of services to be started/running. | `number` | `0` | no |
| <a name="input_ecr"></a> [ecr](#input\_ecr) | ECR repository configuration. | <pre>object({<br>    image_scanning_configuration = object({<br>      scan_on_push = bool<br>    })<br>    image_tag_mutability = string,<br>  })</pre> | <pre>{<br>  "image_scanning_configuration": {<br>    "scan_on_push": true<br>  },<br>  "image_tag_mutability": "MUTABLE"<br>}</pre> | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g. myimage:latest), roll Fargate tasks onto a newer platform version, or immediately deploy ordered\_placement\_strategy and placement\_constraints updates. | `bool` | `false` | no |
| <a name="input_health_check"></a> [health\_check](#input\_health\_check) | A health block containing health check settings for the ALB target groups. See https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#health_check for defaults. | `map(string)` | `{}` | no |
| <a name="input_https_listener_rules"></a> [https\_listener\_rules](#input\_https\_listener\_rules) | A list of maps describing the Listener Rules for this ALB. Required key/values: actions, conditions. Optional key/values: priority, https\_listener\_index (default to https\_listeners[count.index]) | `any` | `[]` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Amount of memory [MB] is required by this service. | `number` | `512` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | The platform version on which to run your service. Defaults to LATEST. | `string` | `"LATEST"` | no |
| <a name="input_policy_document"></a> [policy\_document](#input\_policy\_document) | AWS Policy JSON describing the permissions required for this service. | `string` | `""` | no |
| <a name="input_requires_compatibilities"></a> [requires\_compatibilities](#input\_requires\_compatibilities) | The launch type the task is using. This enables a check to ensure that all of the parameters used in the task definition meet the requirements of the launch type. | `set(string)` | <pre>[<br>  "EC2",<br>  "FARGATE"<br>]</pre> | no |
| <a name="input_requires_internet_access"></a> [requires\_internet\_access](#input\_requires\_internet\_access) | As Fargate does not support IPv6 yet, this is the only way to enable internet access for the service by placing it in a public subnet (but not assigning a public IP). | `bool` | `false` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The service name. Will also be used as Route53 DNS entry. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (\_e.g.\_ { map-migrated : d-example-443255fsf }) | `map(string)` | `{}` | no |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | A list of maps containing key/value pairs that define the target groups to be created. Order of these maps is important and the index of these are to be referenced in listener definitions. Required key/values: name, backend\_protocol, backend\_port | `any` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC id where the load balancer and other resources will be deployed. | `string` | n/a | yes |
| <a name="input_with_appmesh"></a> [with\_appmesh](#input\_with\_appmesh) | This services should be created with an appmesh proxy. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group"></a> [cloudwatch\_log\_group](#output\_cloudwatch\_log\_group) | Name of the CloudWatch log group for container logs. |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | Full ARN of the ECR repository. |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | URL of the ECR repository. |
| <a name="output_ecs_task_exec_role_name"></a> [ecs\_task\_exec\_role\_name](#output\_ecs\_task\_exec\_role\_name) | ECS task role used by this service. |
