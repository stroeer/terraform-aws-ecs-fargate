# terraform-docs

[![Build Status](https://github.com/terraform-docs/terraform-docs/workflows/ci/badge.svg)](https://github.com/terraform-docs/terraform-docs/actions) [![GoDoc](https://pkg.go.dev/badge/github.com/terraform-docs/terraform-docs)](https://pkg.go.dev/github.com/terraform-docs/terraform-docs) [![Go Report Card](https://goreportcard.com/badge/github.com/terraform-docs/terraform-docs)](https://goreportcard.com/report/github.com/terraform-docs/terraform-docs) [![Codecov Report](https://codecov.io/gh/terraform-docs/terraform-docs/branch/master/graph/badge.svg)](https://codecov.io/gh/terraform-docs/terraform-docs) [![License](https://img.shields.io/github/license/terraform-docs/terraform-docs)](https://github.com/terraform-docs/terraform-docs/blob/master/LICENSE) [![Latest release](https://img.shields.io/github/v/release/terraform-docs/terraform-docs)](https://github.com/terraform-docs/terraform-docs/releases)

![terraform-docs-teaser](./images/terraform-docs-teaser.png)

## What is terraform-docs

A utility to generate documentation from Terraform modules in various output formats.

## Installation

macOS users can install using [Homebrew]:

```bash
brew install terraform-docs
```

or

```bash
brew install terraform-docs/tap/terraform-docs
```

Windows users can install using [Scoop]:

```bash
scoop bucket add terraform-docs https://github.com/terraform-docs/scoop-bucket
scoop install terraform-docs
```

or [Chocolatey]:

```bash
choco install terraform-docs
```

Stable binaries are also available on the [releases] page. To install, download the
binary for your platform from "Assets" and place this into your `$PATH`:

```bash
curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.18.0/terraform-docs-v0.18.0-$(uname)-amd64.tar.gz
tar -xzf terraform-docs.tar.gz
chmod +x terraform-docs
mv terraform-docs /usr/local/bin/terraform-docs
```

**NOTE:** Windows releases are in `ZIP` format.

The latest version can be installed using `go install` or `go get`:

```bash
# go1.17+
go install github.com/terraform-docs/terraform-docs@v0.18.0
```

```bash
# go1.16
GO111MODULE="on" go get github.com/terraform-docs/terraform-docs@v0.18.0
```

**NOTE:** please use the latest Go to do this, minimum `go1.16` is required.

This will put `terraform-docs` in `$(go env GOPATH)/bin`. If you encounter the error
`terraform-docs: command not found` after installation then you may need to either add
that directory to your `$PATH` as shown [here] or do a manual installation by cloning
the repo and run `make build` from the repository which will put `terraform-docs` in:

```bash
$(go env GOPATH)/src/github.com/terraform-docs/terraform-docs/bin/$(uname | tr '[:upper:]' '[:lower:]')-amd64/terraform-docs
```

## Usage

### Running the binary directly

To run and generate documentation into README within a directory:

```bash
terraform-docs markdown table --output-file README.md --output-mode inject /path/to/module
```

Check [`output`] configuration for more details and examples.

### Using docker

terraform-docs can be run as a container by mounting a directory with `.tf`
files in it and run the following command:

```bash
docker run --rm --volume "$(pwd):/terraform-docs" -u $(id -u) quay.io/terraform-docs/terraform-docs:0.18.0 markdown /terraform-docs
```

If `output.file` is not enabled for this module, generated output can be redirected
back to a file:

```bash
docker run --rm --volume "$(pwd):/terraform-docs" -u $(id -u) quay.io/terraform-docs/terraform-docs:0.18.0 markdown /terraform-docs > doc.md
```

**NOTE:** Docker tag `latest` refers to _latest_ stable released version and `edge`
refers to HEAD of `master` at any given point in time.

### Using GitHub Actions

To use terraform-docs GitHub Action, configure a YAML workflow file (e.g.
`.github/workflows/documentation.yml`) with the following:

```yaml
name: Generate terraform docs
on:
  - pull_request

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      with:
        ref: ${{ github.event.pull_request.head.ref }}

    - name: Render terraform docs and push changes back to PR
      uses: terraform-docs/gh-actions@main
      with:
        working-dir: .
        output-file: README.md
        output-method: inject
        git-push: "true"
```

Read more about [terraform-docs GitHub Action] and its configuration and
examples.

### pre-commit hook

With pre-commit, you can ensure your Terraform module documentation is kept
up-to-date each time you make a commit.

First [install pre-commit] and then create or update a `.pre-commit-config.yaml`
in the root of your Git repo with at least the following content:

```yaml
repos:
  - repo: https://github.com/terraform-docs/terraform-docs
    rev: "v0.18.0"
    hooks:
      - id: terraform-docs-go
        args: ["markdown", "table", "--output-file", "README.md", "./mymodule/path"]
```

Then run:

```bash
pre-commit install
pre-commit install-hooks
```

Further changes to your module's `.tf` files will cause an update to documentation
when you make a commit.

## Configuration

terraform-docs can be configured with a yaml file. The default name of this file is
`.terraform-docs.yml` and the path order for locating it is:

1. root of module directory
1. `.config/` folder at root of module directory
1. current directory
1. `.config/` folder at current directory
1. `$HOME/.tfdocs.d/`

```yaml
formatter: "" # this is required

version: ""

header-from: main.tf
footer-from: ""

recursive:
  enabled: false
  path: modules
  include-main: true

sections:
  hide: []
  show: []

content: ""

output:
  file: ""
  mode: inject
  template: |-
    <!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_code_deploy"></a> [code\_deploy](#module\_code\_deploy) | ./modules/deployment | n/a |
| <a name="module_container_definition"></a> [container\_definition](#module\_container\_definition) | registry.terraform.io/cloudposse/config/yaml//modules/deepmerge | 1.0.2 |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ./modules/ecr | n/a |
| <a name="module_envoy_container_definition"></a> [envoy\_container\_definition](#module\_envoy\_container\_definition) | registry.terraform.io/cloudposse/config/yaml//modules/deepmerge | 1.0.2 |
| <a name="module_fluentbit_container_definition"></a> [fluentbit\_container\_definition](#module\_fluentbit\_container\_definition) | registry.terraform.io/cloudposse/config/yaml//modules/deepmerge | 1.0.2 |
| <a name="module_otel_container_definition"></a> [otel\_container\_definition](#module\_otel\_container\_definition) | registry.terraform.io/cloudposse/config/yaml//modules/deepmerge | 1.0.2 |
| <a name="module_sg"></a> [sg](#module\_sg) | registry.terraform.io/terraform-aws-modules/security-group/aws | ~> 5.0 |

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
| [aws_iam_policy.acm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cloudwatch_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.fluent_bit_config_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.otel](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ecs_task_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.execute_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.logs_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.acm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.appmesh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.fluent_bit_config_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.otel](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_service_discovery_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_vpc_security_group_egress_rule.trusted_egress_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_definition) | data source |
| [aws_iam_policy.appmesh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.acm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudwatch_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_task_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.enable_execute_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.fluent_bit_config_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logs_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.otel](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_lb.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnets.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_container_definitions"></a> [additional\_container\_definitions](#input\_additional\_container\_definitions) | Additional container definitions added to the task definition of this service, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html for allowed parameters. | `list(any)` | `[]` | no |
| <a name="input_app_mesh"></a> [app\_mesh](#input\_app\_mesh) | Configuration of optional AWS App Mesh integration using an Envoy sidecar. | <pre>object({<br/>    container_definition = optional(any, {})<br/>    container_name       = optional(string, "envoy")<br/>    enabled              = optional(bool, false)<br/>    mesh_name            = optional(string, "apps")<br/><br/>    tls = optional(object({<br/>      acm_certificate_arn = optional(string)<br/>      root_ca_arn         = optional(string)<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_appautoscaling_settings"></a> [appautoscaling\_settings](#input\_appautoscaling\_settings) | Autoscaling configuration for this service. | `map(any)` | `null` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP address to the ENI of this service. | `bool` | `false` | no |
| <a name="input_availability_zone_rebalancing"></a> [availability\_zone\_rebalancing](#input\_availability\_zone\_rebalancing) | ECS automatically redistributes tasks within a service across Availability Zones (AZs) to mitigate the risk of impaired application availability due to underlying infrastructure failures and task lifecycle activities. The valid values are `ENABLED` and `DISABLED`. | `string` | `"DISABLED"` | no |
| <a name="input_capacity_provider_strategy"></a> [capacity\_provider\_strategy](#input\_capacity\_provider\_strategy) | Capacity provider strategies to use for the service. Can be one or more. | <pre>list(object({<br/>    capacity_provider = string<br/>    weight            = string<br/>    base              = optional(string, null)<br/>  }))</pre> | `null` | no |
| <a name="input_cloudwatch_logs"></a> [cloudwatch\_logs](#input\_cloudwatch\_logs) | CloudWatch logs configuration for the containers of this service. CloudWatch logs will be used as the default log configuration if Firelens is disabled and for the fluentbit and otel containers. | <pre>object({<br/>    enabled           = optional(bool, true)<br/>    name              = optional(string, "")<br/>    retention_in_days = optional(number, 7)<br/>  })</pre> | `{}` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ECS cluster id that should run this service | `string` | n/a | yes |
| <a name="input_code_build_environment_compute_type"></a> [code\_build\_environment\_compute\_type](#input\_code\_build\_environment\_compute\_type) | Information about the compute resources the CodeBuild stage of the deployment pipeline will use. | `string` | `"BUILD_LAMBDA_1GB"` | no |
| <a name="input_code_build_environment_image"></a> [code\_build\_environment\_image](#input\_code\_build\_environment\_image) | Docker image to use for the CodeBuild stage of the deployment pipeline. The image needs to include python. | `string` | `"aws/codebuild/amazonlinux-aarch64-lambda-standard:python3.12"` | no |
| <a name="input_code_build_environment_type"></a> [code\_build\_environment\_type](#input\_code\_build\_environment\_type) | Type of build environment for the CodeBuild stage of the deployment pipeline. | `string` | `"ARM_LAMBDA_CONTAINER"` | no |
| <a name="input_code_build_log_retention_in_days"></a> [code\_build\_log\_retention\_in\_days](#input\_code\_build\_log\_retention\_in\_days) | Log retention in days of the CodeBuild CloudWatch log group. | `number` | `7` | no |
| <a name="input_code_build_role_name"></a> [code\_build\_role\_name](#input\_code\_build\_role\_name) | Use an existing role for codebuild permissions that can be reused for multiple services. Otherwise a separate role for this service will be created. | `string` | `""` | no |
| <a name="input_code_pipeline_artifact_bucket"></a> [code\_pipeline\_artifact\_bucket](#input\_code\_pipeline\_artifact\_bucket) | Use an existing bucket for codepipeline artifacts that can be reused for multiple services. Otherwise a separate bucket for each service will be created. | `string` | `""` | no |
| <a name="input_code_pipeline_artifact_bucket_sse"></a> [code\_pipeline\_artifact\_bucket\_sse](#input\_code\_pipeline\_artifact\_bucket\_sse) | AWS KMS master key id for server-side encryption. | `any` | `{}` | no |
| <a name="input_code_pipeline_role_name"></a> [code\_pipeline\_role\_name](#input\_code\_pipeline\_role\_name) | Use an existing role for codepipeline permissions that can be reused for multiple services. Otherwise a separate role for this service will be created. | `string` | `""` | no |
| <a name="input_code_pipeline_type"></a> [code\_pipeline\_type](#input\_code\_pipeline\_type) | Type of the CodePipeline. Possible values are: `V1` and `V2`. | `string` | `"V1"` | no |
| <a name="input_code_pipeline_variables"></a> [code\_pipeline\_variables](#input\_code\_pipeline\_variables) | CodePipeline variables. Valid only when `codepipeline_type` is `V2`. | <pre>list(object({<br/>    name          = string<br/>    default_value = optional(string)<br/>    description   = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_codestar_notifications_detail_type"></a> [codestar\_notifications\_detail\_type](#input\_codestar\_notifications\_detail\_type) | The level of detail to include in the notifications for this resource. Possible values are BASIC and FULL. | `string` | `"BASIC"` | no |
| <a name="input_codestar_notifications_event_type_ids"></a> [codestar\_notifications\_event\_type\_ids](#input\_codestar\_notifications\_event\_type\_ids) | A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api. | `list(string)` | <pre>[<br/>  "codepipeline-pipeline-pipeline-execution-succeeded",<br/>  "codepipeline-pipeline-pipeline-execution-failed"<br/>]</pre> | no |
| <a name="input_codestar_notifications_kms_master_key_id"></a> [codestar\_notifications\_kms\_master\_key\_id](#input\_codestar\_notifications\_kms\_master\_key\_id) | AWS KMS master key id for server-side encryption. | `string` | `null` | no |
| <a name="input_codestar_notifications_target_arn"></a> [codestar\_notifications\_target\_arn](#input\_codestar\_notifications\_target\_arn) | Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created. | `string` | `""` | no |
| <a name="input_container_definition_overwrites"></a> [container\_definition\_overwrites](#input\_container\_definition\_overwrites) | Additional container definition parameters or overwrites of defaults for your service, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html for allowed parameters. | `any` | `{}` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Defaults to var.service\_name, can be overridden if it differs. Used as a target for LB. | `string` | `""` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port used by the app within the container. | `number` | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Amount of CPU required by this service. 1024 == 1 vCPU | `number` | `256` | no |
| <a name="input_cpu_architecture"></a> [cpu\_architecture](#input\_cpu\_architecture) | Must be set to either `X86_64` or `ARM64`, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform. | `string` | `"X86_64"` | no |
| <a name="input_create_deployment_pipeline"></a> [create\_deployment\_pipeline](#input\_create\_deployment\_pipeline) | Creates a deploy pipeline from ECR trigger if `create_ecr_repo == true`. | `bool` | `true` | no |
| <a name="input_create_ecr_repository"></a> [create\_ecr\_repository](#input\_create\_ecr\_repository) | Create an ECR repository for this service. | `bool` | `true` | no |
| <a name="input_create_ingress_security_group"></a> [create\_ingress\_security\_group](#input\_create\_ingress\_security\_group) | Create a security group allowing ingress from target groups to the application ports. Disable this for target groups attached to a Network Loadbalancer. | `bool` | `true` | no |
| <a name="input_deployment_circuit_breaker"></a> [deployment\_circuit\_breaker](#input\_deployment\_circuit\_breaker) | Deployment circuit breaker configuration. | <pre>object({<br/>    enable   = bool<br/>    rollback = bool<br/>  })</pre> | <pre>{<br/>  "enable": false,<br/>  "rollback": false<br/>}</pre> | no |
| <a name="input_deployment_failure_detection_alarms"></a> [deployment\_failure\_detection\_alarms](#input\_deployment\_failure\_detection\_alarms) | CloudWatch alarms used to detect deployment failures. | <pre>object({<br/>    enable      = bool<br/>    rollback    = bool<br/>    alarm_names = list(string)<br/>  })</pre> | <pre>{<br/>  "alarm_names": [],<br/>  "enable": false,<br/>  "rollback": false<br/>}</pre> | no |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | Upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment. Not valid when using the `DAEMON` scheduling strategy. | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | Lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment. | `number` | `100` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Desired count of services to be started/running. | `number` | `0` | no |
| <a name="input_ecr_custom_lifecycle_policy"></a> [ecr\_custom\_lifecycle\_policy](#input\_ecr\_custom\_lifecycle\_policy) | JSON formatted ECR lifecycle policy used for this repository (disabled the default lifecycle policy), see https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters for details. | `string` | `null` | no |
| <a name="input_ecr_enable_default_lifecycle_policy"></a> [ecr\_enable\_default\_lifecycle\_policy](#input\_ecr\_enable\_default\_lifecycle\_policy) | Enables an ECR lifecycle policy for this repository which expires all images except for the last 30. | `bool` | `true` | no |
| <a name="input_ecr_force_delete"></a> [ecr\_force\_delete](#input\_ecr\_force\_delete) | If `true`, will delete this repository even if it contains images. | `bool` | `false` | no |
| <a name="input_ecr_image_scanning_configuration"></a> [ecr\_image\_scanning\_configuration](#input\_ecr\_image\_scanning\_configuration) | n/a | `map(any)` | <pre>{<br/>  "scan_on_push": true<br/>}</pre> | no |
| <a name="input_ecr_image_tag"></a> [ecr\_image\_tag](#input\_ecr\_image\_tag) | Tag of the new image pushed to the Amazon ECR repository to trigger the deployment pipeline. | `string` | `"production"` | no |
| <a name="input_ecr_image_tag_mutability"></a> [ecr\_image\_tag\_mutability](#input\_ecr\_image\_tag\_mutability) | n/a | `string` | `"MUTABLE"` | no |
| <a name="input_ecr_repository_name"></a> [ecr\_repository\_name](#input\_ecr\_repository\_name) | Existing repo to register to use with this service module, e.g. creating deployment pipelines. | `string` | `""` | no |
| <a name="input_efs_volumes"></a> [efs\_volumes](#input\_efs\_volumes) | Configuration block for EFS volumes. | `any` | `[]` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Specifies whether to enable Amazon ECS Exec for the tasks within the service. | `bool` | `false` | no |
| <a name="input_extra_port_mappings"></a> [extra\_port\_mappings](#input\_extra\_port\_mappings) | Additional ports to be exposed from the container. | <pre>list(object({<br/>    hostPort      = number<br/>    containerPort = number<br/>    protocol      = optional(string, "tcp")<br/>  }))</pre> | `[]` | no |
| <a name="input_firelens"></a> [firelens](#input\_firelens) | Configuration for optional custom log routing using FireLens over fluentbit sidecar. Enable `attach_init_config_s3_policy` to attach an IAM policy granting access to the init config files on S3. | <pre>object({<br/>    attach_init_config_s3_policy = optional(bool, false)<br/>    container_name               = optional(string, "fluentbit")<br/>    container_definition         = optional(any, {})<br/>    enabled                      = optional(bool, false)<br/>    init_config_files            = optional(list(string), [])<br/>    log_level                    = optional(string, "info")<br/>    opensearch_host              = optional(string, "")<br/>    aws_region                   = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g. myimage:latest), roll Fargate tasks onto a newer platform version, or immediately deploy ordered\_placement\_strategy and placement\_constraints updates. | `bool` | `false` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers. | `number` | `0` | no |
| <a name="input_https_listener_rules"></a> [https\_listener\_rules](#input\_https\_listener\_rules) | A list of maps describing the Listener Rules for this ALB. Required key/values: actions, conditions. Optional key/values: priority, https\_listener\_index (default to https\_listeners[count.index]) | `any` | `[]` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Amount of memory [MB] is required by this service. | `number` | `512` | no |
| <a name="input_operating_system_family"></a> [operating\_system\_family](#input\_operating\_system\_family) | If the `requires_compatibilities` is `FARGATE` this field is required. Must be set to a valid option from https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform. | `string` | `"LINUX"` | no |
| <a name="input_otel"></a> [otel](#input\_otel) | Configuration for (optional) AWS Distro für OpenTelemetry sidecar. | <pre>object({<br/>    container_definition = optional(any, {})<br/>    enabled              = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | The platform version on which to run your service. Defaults to LATEST. | `string` | `"LATEST"` | no |
| <a name="input_policy_document"></a> [policy\_document](#input\_policy\_document) | AWS Policy JSON describing the permissions required for this service. | `string` | `""` | no |
| <a name="input_requires_compatibilities"></a> [requires\_compatibilities](#input\_requires\_compatibilities) | The launch type the task is using. This enables a check to ensure that all of the parameters used in the task definition meet the requirements of the launch type. | `set(string)` | <pre>[<br/>  "EC2",<br/>  "FARGATE"<br/>]</pre> | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | A list of security group ids that will be attached additionally to the ecs deployment. | `list(string)` | `[]` | no |
| <a name="input_service_discovery_dns_namespace"></a> [service\_discovery\_dns\_namespace](#input\_service\_discovery\_dns\_namespace) | The ID of a Service Discovery private DNS namespace. If provided, the module will create a Route 53 Auto Naming Service to enable service discovery using Cloud Map. | `string` | `""` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The service name. Will also be used as Route53 DNS entry. | `string` | n/a | yes |
| <a name="input_subnet_tags"></a> [subnet\_tags](#input\_subnet\_tags) | Map of tags to identify the subnets associated with this service. Each pair must exactly match a pair on the desired subnet. Defaults to `{ Tier = public }` for services with `assign_public_ip == true` and { Tier = private } otherwise. | `map(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (\_e.g.\_ { map-migrated : d-example-443255fsf }) | `map(string)` | `{}` | no |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | A list of maps containing key/value pairs that define the target groups to be created. Order of these maps is important and the index of these are to be referenced in listener definitions. Required key/values: name, backend\_protocol, backend\_port | `any` | `[]` | no |
| <a name="input_task_execution_role_arn"></a> [task\_execution\_role\_arn](#input\_task\_execution\_role\_arn) | ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. If not provided, a default role will be created and used. | `string` | `""` | no |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | ARN of the IAM role that allows your Amazon ECS container task to make calls to other AWS services. If not specified, the default ECS task role created in this module will be used. | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC id where the load balancer and other resources will be deployed. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_target_group_arn_suffixes"></a> [alb\_target\_group\_arn\_suffixes](#output\_alb\_target\_group\_arn\_suffixes) | ARN suffixes of the created target groups. |
| <a name="output_alb_target_group_arns"></a> [alb\_target\_group\_arns](#output\_alb\_target\_group\_arns) | ARNs of the created target groups. |
| <a name="output_autoscaling_target"></a> [autoscaling\_target](#output\_autoscaling\_target) | ECS auto scaling targets if auto scaling enabled. |
| <a name="output_cloudwatch_log_group"></a> [cloudwatch\_log\_group](#output\_cloudwatch\_log\_group) | Name of the CloudWatch log group for container logs. |
| <a name="output_container_definitions"></a> [container\_definitions](#output\_container\_definitions) | Container definitions used by this service including all sidecars. |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | Full ARN of the ECR repository. |
| <a name="output_ecr_repository_id"></a> [ecr\_repository\_id](#output\_ecr\_repository\_id) | The registry ID where the repository was created. |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | The URL of the repository (in the form `aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName`) |
| <a name="output_task_execution_role_arn"></a> [task\_execution\_role\_arn](#output\_task\_execution\_role\_arn) | ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. |
| <a name="output_task_execution_role_name"></a> [task\_execution\_role\_name](#output\_task\_execution\_role\_name) | Friendly name of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. |
| <a name="output_task_execution_role_unique_id"></a> [task\_execution\_role\_unique\_id](#output\_task\_execution\_role\_unique\_id) | Stable and unique string identifying the IAM role that the Amazon ECS container agent and the Docker daemon can assume. |
| <a name="output_task_role_arn"></a> [task\_role\_arn](#output\_task\_role\_arn) | ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services. |
| <a name="output_task_role_name"></a> [task\_role\_name](#output\_task\_role\_name) | Friendly name of IAM role that allows your Amazon ECS container task to make calls to other AWS services. |
| <a name="output_task_role_unique_id"></a> [task\_role\_unique\_id](#output\_task\_role\_unique\_id) | Stable and unique string identifying the IAM role that allows your Amazon ECS container task to make calls to other AWS services. |
<!-- END_TF_DOCS -->

output-values:
  enabled: false
  from: ""

sort:
  enabled: true
  by: name

settings:
  anchor: true
  color: true
  default: true
  description: false
  escape: true
  hide-empty: false
  html: true
  indent: 2
  lockfile: true
  read-comments: true
  required: true
  sensitive: true
  type: true
```

## Content Template

Generated content can be customized further away with `content` in configuration.
If the `content` is empty the default order of sections is used.

Compatible formatters for customized content are `asciidoc` and `markdown`. `content`
will be ignored for other formatters.

`content` is a Go template with following additional variables:

- `{{ .Header }}`
- `{{ .Footer }}`
- `{{ .Inputs }}`
- `{{ .Modules }}`
- `{{ .Outputs }}`
- `{{ .Providers }}`
- `{{ .Requirements }}`
- `{{ .Resources }}`

and following functions:

- `{{ include "relative/path/to/file" }}`

These variables are the generated output of individual sections in the selected
formatter. For example `{{ .Inputs }}` is Markdown Table representation of _inputs_
when formatter is set to `markdown table`.

Note that sections visibility (i.e. `sections.show` and `sections.hide`) takes
precedence over the `content`.

Additionally there's also one extra special variable avaialble to the `content`:

- `{{ .Module }}`

As opposed to the other variables mentioned above, which are generated sections
based on a selected formatter, the `{{ .Module }}` variable is just a `struct`
representing a [Terraform module].

````yaml
content: |-
  Any arbitrary text can be placed anywhere in the content

  {{ .Header }}

  and even in between sections

  {{ .Providers }}

  and they don't even need to be in the default order

  {{ .Outputs }}

  include any relative files

  {{ include "relative/path/to/file" }}

  {{ .Inputs }}

  # Examples

  ```hcl
  {{ include "examples/foo/main.tf" }}
  ```

  ## Resources

  {{ range .Module.Resources }}
  - {{ .GetMode }}.{{ .Spec }} ({{ .Position.Filename }}#{{ .Position.Line }})
  {{- end }}
````

## Build on top of terraform-docs

terraform-docs primary use-case is to be utilized as a standalone binary, but
some parts of it is also available publicly and can be imported in your project
as a library.

```go
import (
    "github.com/terraform-docs/terraform-docs/format"
    "github.com/terraform-docs/terraform-docs/print"
    "github.com/terraform-docs/terraform-docs/terraform"
)

// buildTerraformDocs for module root `path` and provided content `tmpl`.
func buildTerraformDocs(path string, tmpl string) (string, error) {
    config := print.DefaultConfig()
    config.ModuleRoot = path // module root path (can be relative or absolute)

    module, err := terraform.LoadWithOptions(config)
    if err != nil {
        return "", err
    }

    // Generate in Markdown Table format
    formatter := format.NewMarkdownTable(config)

    if err := formatter.Generate(module); err != nil {
        return "", err
    }

    // // Note: if you don't intend to provide additional template for the generated
    // // content, or the target format doesn't provide templating (e.g. json, yaml,
    // // xml, or toml) you can use `Content()` function instead of `Render()`.
    // // `Content()` returns all the sections combined with predefined order.
    // return formatter.Content(), nil

    return formatter.Render(tmpl)
}
```

## Plugin

Generated output can be heavily customized with [`content`], but if using that
is not enough for your use-case, you can write your own plugin.

In order to install a plugin the following steps are needed:

- download the plugin and place it in `~/.tfdocs.d/plugins` (or `./.tfdocs.d/plugins`)
- make sure the plugin file name is `tfdocs-format-<NAME>`
- modify [`formatter`] of `.terraform-docs.yml` file to be `<NAME>`

**Important notes:**

- if the plugin file name is different than the example above, terraform-docs won't
be able to to pick it up nor register it properly
- you can only use plugin thorough `.terraform-docs.yml` file and it cannot be used
with CLI arguments

To create a new plugin create a new repository called `tfdocs-format-<NAME>` with
following `main.go`:

```go
package main

import (
    _ "embed" //nolint

    "github.com/terraform-docs/terraform-docs/plugin"
    "github.com/terraform-docs/terraform-docs/print"
    "github.com/terraform-docs/terraform-docs/template"
    "github.com/terraform-docs/terraform-docs/terraform"
)

func main() {
    plugin.Serve(&plugin.ServeOpts{
        Name:    "<NAME>",
        Version: "0.1.0",
        Printer: printerFunc,
    })
}

//go:embed sections.tmpl
var tplCustom []byte

// printerFunc the function being executed by the plugin client.
func printerFunc(config *print.Config, module *terraform.Module) (string, error) {
    tpl := template.New(config,
        &template.Item{Name: "custom", Text: string(tplCustom)},
    )

    rendered, err := tpl.Render("custom", module)
    if err != nil {
        return "", err
    }

    return rendered, nil
}
```

Please refer to [tfdocs-format-template] for more details. You can create a new
repository from it by clicking on `Use this template` button.

## Documentation

- **Users**
  - Read the [User Guide] to learn how to use terraform-docs
  - Read the [Formats Guide] to learn about different output formats of terraform-docs
  - Refer to [Config File Reference] for all the available configuration options
- **Developers**
  - Read [Contributing Guide] before submitting a pull request

Visit [our website] for all documentation.

## Community

- Discuss terraform-docs on [Slack]

## License

MIT License - Copyright (c) 2021 The terraform-docs Authors.

[Chocolatey]: https://www.chocolatey.org
[Config File Reference]: https://terraform-docs.io/user-guide/configuration/
[`content`]: https://terraform-docs.io/user-guide/configuration/content/
[Contributing Guide]: CONTRIBUTING.md
[Formats Guide]: https://terraform-docs.io/reference/terraform-docs/
[`formatter`]: https://terraform-docs.io/user-guide/configuration/formatter/
[here]: https://golang.org/doc/code.html#GOPATH
[Homebrew]: https://brew.sh
[install pre-commit]: https://pre-commit.com/#install
[`output`]: https://terraform-docs.io/user-guide/configuration/output/
[releases]: https://github.com/terraform-docs/terraform-docs/releases
[Scoop]: https://scoop.sh/
[Slack]: https://slack.terraform-docs.io/
[terraform-docs GitHub Action]: https://github.com/terraform-docs/gh-actions
[Terraform module]: https://pkg.go.dev/github.com/terraform-docs/terraform-docs/terraform#Module
[tfdocs-format-template]: https://github.com/terraform-docs/tfdocs-format-template
[our website]: https://terraform-docs.io/
[User Guide]: https://terraform-docs.io/user-guide/introduction/
