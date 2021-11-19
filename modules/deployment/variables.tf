# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  type        = string
  description = "Target ECS cluster used for deployments."
}

variable "ecr_repository_name" {
  type        = string
  description = "Name of the ECR repository for wich a trigger will be created to start the deployment pipeline."
}

variable "service_name" {
  type        = string
  description = "The service's name to create the pipeline resources."
}

variable "container_name" {
  type        = string
  description = "The service's main container to create the pipeline resources."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "enabled" {
  default     = true
  description = "Conditionally enables this module (and all it's ressources)."
  type        = bool
}

variable "artifact_bucket" {
  default     = ""
  description = "Use an existing bucket for codepipeline artifacts that can be reused for multiple services."
  type        = string
}

variable "code_pipeline_role" {
  default     = ""
  description = "Use an existing role for codepipeline permissions that can be reused for multiple services."
  type        = string
}

variable "code_build_role" {
  default     = ""
  description = "Use an existing role for codebuild permissions that can be reused for multiple services."
  type        = string
}

variable "codestar_notifications_detail_type" {
  default     = "BASIC"
  description = "The level of detail to include in the notifications for this resource. Possible values are BASIC and FULL."
  type        = string
}

variable "codestar_notifications_event_type_ids" {
  default     = ["codepipeline-pipeline-pipeline-execution-succeeded", "codepipeline-pipeline-pipeline-execution-failed"]
  description = "A list of event types associated with this notification rule. For list of allowed events see https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#concepts-api."
  type        = list(string)
}

variable "codestar_notifications_target_arn" {
  default     = ""
  description = "Use an existing ARN for a notification rule target (for example, a SNS Topic ARN). Otherwise a separate sns topic for this service will be created."
  type        = string
}

variable "tags" {
  default     = {}
  description = "Additional tags (_e.g._ { map-migrated : d-example-443255fsf })"
  type        = map(string)
}


