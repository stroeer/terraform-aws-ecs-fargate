# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_id" {
  description = "The ECS cluster id that should run this service"
  type        = string
}

variable "container_port" {
  description = "The port used by the app within the container."
  type        = number
}

variable "service_name" {
  description = "The service name. Will also be used as Route53 DNS entry."
  type        = string
}

variable "vpc_id" {
  description = "VPC id where the load balancer and other resources will be deployed."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "additional_container_definitions" {
  default     = []
  description = "Additional container definitions added to the task definition of this service, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html for allowed parameters."
  type        = list(any)
}

variable "app_mesh" {
  default     = {}
  description = "Configuration of optional AWS App Mesh integration using an Envoy sidecar."
  type = object({
    container_definition = optional(any, {})
    container_name       = optional(string, "envoy")
    enabled              = optional(bool, false)
    mesh_name            = optional(string, "apps")

    tls = optional(object({
      acm_certificate_arn = optional(string)
      root_ca_arn         = optional(string)
    }), {})
  })
}

variable "appautoscaling_settings" {
  default     = null
  description = "Autoscaling configuration for this service."
  type        = map(any)
}

variable "assign_public_ip" {
  default     = false
  description = "Assign a public IP address to the ENI of this service."
  type        = bool
}

variable "capacity_provider_strategy" {
  default     = null
  description = "Capacity provider strategies to use for the service. Can be one or more."
  type = list(object({
    capacity_provider = string
    weight            = string
    base              = optional(string, null)
  }))
}

variable "container_definition_overwrites" {
  default     = {}
  description = "Additional container definition parameters or overwrites of defaults for your service, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html for allowed parameters."
  type        = any
}

variable "deployment_circuit_breaker" {
  default = {
    enable   = false
    rollback = false
  }
  description = "Deployment circuit breaker configuration."
  type = object({
    enable   = bool
    rollback = bool
  })
}

variable "deployment_failure_detection_alarms" {
  default = {
    enable      = false
    rollback    = false
    alarm_names = []
  }

  description = "CloudWatch alarms used to detect deployment failures."
  type = object({
    enable      = bool
    rollback    = bool
    alarm_names = list(string)
  })
}


variable "cloudwatch_logs" {
  description = "CloudWatch logs configuration for the containers of this service. CloudWatch logs will be used as the default log configuration if Firelens is disabled and for the fluentbit and otel containers."
  default     = {}
  type = object({
    enabled           = optional(bool, true)
    name              = optional(string, "")
    retention_in_days = optional(number, 7)
  })
}

variable "container_name" {
  default     = ""
  description = "Defaults to var.service_name, can be overridden if it differs. Used as a target for LB."
  type        = string
}

/*
Supported task CPU and memory values for Fargate tasks are as follows.

CPU value 	    | Memory value (MiB)
-----------------------------------------------------------------------------------------------------
256 (.25 vCPU) 	| 512 (0.5GB), 1024 (1GB), 2048 (2GB)
512 (.5 vCPU) 	| 1024 (1GB), 2048 (2GB), 3072 (3GB), 4096 (4GB)
1024 (1 vCPU) 	| 2048 (2GB), 3072 (3GB), 4096 (4GB), 5120 (5GB), 6144 (6GB), 7168 (7GB), 8192 (8GB)
2048 (2 vCPU) 	| Between 4096 (4GB) and 16384 (16GB) in increments of 1024 (1GB)
4096 (4 vCPU) 	| Between 8192 (8GB) and 30720 (30GB) in increments of 1024 (1GB)
*/

variable "cpu" {
  default     = 256
  description = "Amount of CPU required by this service. 1024 == 1 vCPU"
  type        = number
}

variable "cpu_architecture" {
  default     = "X86_64"
  description = "Must be set to either `X86_64` or `ARM64`, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform."
  type        = string
}

variable "code_pipeline_artifact_bucket" {
  default     = ""
  description = "Use an existing bucket for codepipeline artifacts that can be reused for multiple services. Otherwise a separate bucket for each service will be created."
  type        = string
}

variable "code_pipeline_artifact_bucket_sse" {
  default     = {}
  description = "AWS KMS master key id for server-side encryption."
  type        = any
}

variable "code_pipeline_role_name" {
  default     = ""
  description = "Use an existing role for codepipeline permissions that can be reused for multiple services. Otherwise a separate role for this service will be created."
  type        = string
}

variable "code_pipeline_type" {
  description = "Type of the CodePipeline. Possible values are: `V1` and `V2`."
  default     = "V1"
  type        = string
}

variable "code_pipeline_variables" {
  description = "CodePipeline variables. Valid only when `codepipeline_type` is `V2`."
  default     = []
  type = list(object({
    name          = string
    default_value = optional(string)
    description   = optional(string)
  }))
}

variable "code_build_environment_compute_type" {
  description = "Information about the compute resources the CodeBuild stage of the deployment pipeline will use."
  default     = "BUILD_LAMBDA_1GB"
  type        = string
  nullable    = false
}

variable "code_build_environment_image" {
  description = "Docker image to use for the CodeBuild stage of the deployment pipeline. The image needs to include python."
  default     = "aws/codebuild/amazonlinux-aarch64-lambda-standard:python3.12"
  type        = string
  nullable    = false
}

variable "code_build_environment_type" {
  description = "Type of build environment for the CodeBuild stage of the deployment pipeline."
  default     = "ARM_LAMBDA_CONTAINER"
  type        = string
  nullable    = false
}

variable "code_build_role_name" {
  default     = ""
  description = "Use an existing role for codebuild permissions that can be reused for multiple services. Otherwise a separate role for this service will be created."
  type        = string
}

variable "code_build_log_retention_in_days" {
  default     = 7
  description = "Log retention in days of the CodeBuild CloudWatch log group."
  type        = number
}

variable "codestar_notifications_detail_type" {
  default     = "BASIC"
  description = "The level of detail to include in the notifications for this resource. Possible values are BASIC and FULL."
  type        = string
}

variable "codestar_notifications_event_type_ids" {
  default = [
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-pipeline-execution-failed"
  ]
  description = "A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api."
  type        = list(string)
}

variable "codestar_notifications_target_arn" {
  default     = ""
  description = "Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created."
  type        = string
}

variable "codestar_notifications_kms_master_key_id" {
  default     = null
  description = "AWS KMS master key id for server-side encryption."
  type        = string
}

variable "create_deployment_pipeline" {
  default     = true
  description = "Creates a deploy pipeline from ECR trigger if `create_ecr_repo == true`."
  type        = bool
}

variable "create_ecr_repository" {
  default     = true
  description = "Create an ECR repository for this service."
  type        = bool
}

variable "create_ingress_security_group" {
  default     = true
  description = "Create a security group allowing ingress from target groups to the application ports. Disable this for target groups attached to a Network Loadbalancer."
  type        = bool
}

variable "deployment_maximum_percent" {
  description = "Upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment. Not valid when using the `DAEMON` scheduling strategy."
  default     = 200
  type        = number
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment."
  default     = 100
  type        = number
}

variable "desired_count" {
  default     = 0
  description = "Desired count of services to be started/running."
  type        = number
}

variable "ecr_repository_name" {
  default     = ""
  description = "Existing repo to register to use with this service module, e.g. creating deployment pipelines."
  type        = string
}

variable "enable_execute_command" {
  default     = false
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service."
  type        = bool
}

variable "ecr_custom_lifecycle_policy" {
  default     = null
  description = "JSON formatted ECR lifecycle policy used for this repository (disabled the default lifecycle policy), see https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html#lifecycle_policy_parameters for details."
  type        = string
}

variable "ecr_enable_default_lifecycle_policy" {
  default     = true
  description = "Enables an ECR lifecycle policy for this repository which expires all images except for the last 30."
  type        = bool
}

variable "ecr_force_delete" {
  default     = false
  description = "If `true`, will delete this repository even if it contains images."
  type        = bool
}

variable "ecr_image_scanning_configuration" {
  type = map(any)
  default = {
    scan_on_push = true
  }
}

variable "ecr_image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "efs_volumes" {
  default     = []
  description = "Configuration block for EFS volumes."
  type        = any
}

variable "firelens" {
  description = "Configuration for optional custom log routing using FireLens over fluentbit sidecar. Enable `attach_init_config_s3_policy` to attach an IAM policy granting access to the init config files on S3."
  default     = {}
  type = object({
    attach_init_config_s3_policy = optional(bool, false)
    container_name               = optional(string, "fluentbit")
    container_definition         = optional(any, {})
    enabled                      = optional(bool, false)
    init_config_files            = optional(list(string), [])
    log_level                    = optional(string, "info")
    opensearch_host              = optional(string, "")
    aws_region                   = optional(string)
  })
}

variable "force_new_deployment" {
  default     = false
  description = "Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g. myimage:latest), roll Fargate tasks onto a newer platform version, or immediately deploy ordered_placement_strategy and placement_constraints updates."
  type        = bool
}

variable "health_check_grace_period_seconds" {
  default     = 0
  type        = number
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers."
}

variable "https_listener_rules" {
  description = "A list of maps describing the Listener Rules for this ALB. Required key/values: actions, conditions. Optional key/values: priority, https_listener_index (default to https_listeners[count.index])"
  type        = any
  default     = []
}

variable "ecr_image_tag" {
  default     = "production"
  description = "Tag of the new image pushed to the Amazon ECR repository to trigger the deployment pipeline."
  type        = string
}

variable "memory" {
  default     = 512
  description = "Amount of memory [MB] is required by this service."
  type        = number
}

variable "otel" {
  default     = {}
  description = "Configuration for (optional) AWS Distro für OpenTelemetry sidecar."
  type = object({
    container_definition = optional(any, {})
    enabled              = optional(bool, false)
  })
}

variable "platform_version" {
  default     = "LATEST"
  description = "The platform version on which to run your service. Defaults to LATEST."
  type        = string
}

variable "policy_document" {
  default     = ""
  description = "AWS Policy JSON describing the permissions required for this service."
  type        = string
}

variable "operating_system_family" {
  default     = "LINUX"
  description = "If the `requires_compatibilities` is `FARGATE` this field is required. Must be set to a valid option from https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform."
  type        = string
}

variable "requires_compatibilities" {
  default     = ["EC2", "FARGATE"]
  description = "The launch type the task is using. This enables a check to ensure that all of the parameters used in the task definition meet the requirements of the launch type."
  type        = set(string)
}

variable "security_groups" {
  description = "A list of security group ids that will be attached additionally to the ecs deployment."
  type        = list(string)
  default     = []
}

variable "service_discovery_dns_namespace" {
  description = "The ID of a Service Discovery private DNS namespace. If provided, the module will create a Route 53 Auto Naming Service to enable service discovery using Cloud Map."
  type        = string
  default     = ""
}

variable "subnet_tags" {
  description = "Map of tags to identify the subnets associated with this service. Each pair must exactly match a pair on the desired subnet. Defaults to `{ Tier = public }` for services with `assign_public_ip == true` and { Tier = private } otherwise."
  type        = map(string)
  default     = null
}

variable "tags" {
  default     = {}
  description = "Additional tags (_e.g._ { map-migrated : d-example-443255fsf })"
  type        = map(string)
}

variable "target_groups" {
  description = "A list of maps containing key/value pairs that define the target groups to be created. Order of these maps is important and the index of these are to be referenced in listener definitions. Required key/values: name, backend_protocol, backend_port"
  type        = any
  default     = []
}

variable "task_execution_role_arn" {
  description = "ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. If not provided, a default role will be created and used."
  type        = string
  default     = ""
}

variable "task_role_arn" {
  default     = ""
  description = "ARN of the IAM role that allows your Amazon ECS container task to make calls to other AWS services. If not specified, the default ECS task role created in this module will be used."
  type        = string
}
