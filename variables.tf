# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "alb_listener_priority" {
  description = "Ordering of listeners, must be unique."
  type        = number
}

variable "cluster_id" {
  description = "The ECS cluster id that should run this service"
  type        = string
}

variable "container_definitions" {
  # Full documentation here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html
  description = "JSON container definition."
  type        = string
}

variable "container_port" {
  description = "The port used by the web app within the container"
  type        = number
}

variable "health_check_endpoint" {
  description = "Endpoint (/health) that will be probed by the LB to determine the service's health."
  type        = string
}

variable "service_name" {
  description = "The service name. Will also be used as Route53 DNS entry."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "assign_public_ip" {
  default     = false
  description = "As Fargate does not support IPv6 yet, this is the only way to enable internet access for the service."
  type        = bool
}

variable "container_name" {
  default     = ""
  description = "Defaults to var.service_name, can be overriden if it differs. Used as a target for LB."
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

variable "create_deployment_pipeline" {
  default     = true
  description = "Creates a deploy pipeline from ECR trigger."
  type        = bool
}

variable "create_log_streaming" {
  default     = true
  description = "Creates a Kinesis Firehose delivery stream for streaming application logs to an existing Elasticsearch domain."
  type        = bool
}

variable "desired_count" {
  type        = number
  default     = 0
  description = "Desired count of services to be started/running."
}

variable "ecr" {
  description = "ECR repository configuration."
  type = object({
    image_scanning_configuration = object({
      scan_on_push = bool
    })
    image_tag_mutability = string,
  })

  # if you change any of the defaults, the whole configuration object needs to be provided. 
  # https://github.com/hashicorp/terraform/issues/19898 will probably change this
  default = {
    image_scanning_configuration = {
      scan_on_push = false
    }
    image_tag_mutability = "MUTABLE",
  }
}

variable "logs_firehose_delivery_stream_s3_backup_bucket_arn" {
  default     = ""
  description = "Use an existing S3 bucket to backup log documents which couldn't be streamed to Elasticsearch. Otherwise a separate bucket for this service will be created."
}

variable "logs_fluentbit_cloudwatch_log_group_name" {
  default     = ""
  description = "Use an existing CloudWatch log group for storing logs of the fluent-bit sidecar. Otherwise a dedicate log group for this service will be created."
  type        = string
}


variable "logs_domain_name" {
  default     = "application-logs"
  description = "The name of an existing Elasticsearch domain used as destination for the Firehose delivery stream."
  type        = string
}

variable "memory" {
  default     = 512
  description = "Amount of memory [MB] is required by this service."
  type        = number
}

variable "policy_document" {
  default     = ""
  description = "AWS Policy JSON describing the permissions required for this service."
  type        = string
}

variable "with_appmesh" {
  default     = false
  description = "This services should be created with an appmesh proxy."
  type        = bool
}
