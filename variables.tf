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


variable "assign_public_ip" {
  default     = false
  description = "This services will be placed in a public subnet and be assigned a public routable IP."
  type        = bool
}

variable "appautoscaling_settings" {
  default     = null
  description = "Autoscaling configuration for this service."
  type        = map(any)
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

variable "code_build_role_name" {
  default     = ""
  description = "Use an existing role for codebuild permissions that can be reused for multiple services. Otherwise a separate role for this service will be created."
  type        = string
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

variable "create_deployment_pipeline" {
  default     = true
  description = "Creates a deploy pipeline from ECR trigger if `create_ecr_repo == true`."
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
  description = "Configuration for optional custom log routing using FireLens over fluentbit sidecar."
  default     = {}
  type = object({
    container_definition = optional(any, {})
    enabled              = optional(bool, false)
    opensearch_host      = optional(string, "")
  })
}

variable "force_new_deployment" {
  default     = false
  description = "Enable to force a new task deployment of the service. This can be used to update tasks to use a newer Docker image with same image/tag combination (e.g. myimage:latest), roll Fargate tasks onto a newer platform version, or immediately deploy ordered_placement_strategy and placement_constraints updates."
  type        = bool
}

variable "https_listener_rules" {
  description = "A list of maps describing the Listener Rules for this ALB. Required key/values: actions, conditions. Optional key/values: priority, https_listener_index (default to https_listeners[count.index])"
  type        = any
  default     = []
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

variable "requires_compatibilities" {
  default     = ["EC2", "FARGATE"]
  description = "The launch type the task is using. This enables a check to ensure that all of the parameters used in the task definition meet the requirements of the launch type."
  type        = set(string)
}

variable "requires_internet_access" {
  default     = false
  description = "As Fargate does not support IPv6 yet, this is the only way to enable internet access for the service by placing it in a public subnet (but not assigning a public IP)."
  type        = bool
}

variable "security_groups" {
  description = "A list of security group ids that will be attached additionally to the ecs deployment."
  type        = list(string)
  default     = []
}

variable "subnet_tags" {
  description = "The subnet tags where the ecs service will be deployed. If not specified all subnets will be used."
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
