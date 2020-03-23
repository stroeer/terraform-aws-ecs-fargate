# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "alb_listener_priority" {
  type        = number
  description = "Ordering of listers, must be unique."
}

variable "cluster_id" {
  type        = string
  description = "The ECS cluster id that should run this service."
}

variable "container_definitions" {
  type = string
  # Full documentation here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html
  description = "JSON container definition."
}

variable "container_port" {
  type        = number
  description = "The port used by the web app within the container."
}

variable "health_check_endpoint" {
  description = "Endpoint (/health) that will be probed by the LB to determine the service's health."
  type        = string
}

variable "service_name" {
  type        = string
  description = "The service name. Will also be used as Route53 DNS entry."
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

variable "desired_count" {
  default     = 0
  description = "Desired count of services to be started/running."
  type        = number
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

variable "use_code_deploy" {
  default     = false
  description = "Creates a code-deploy pipeline from ECR trigger"
  type        = bool
}

/* add permissions for this service
data "aws_iam_policy_document" "s3_reader" {
  statement {
    actions   = ["s3:Get*"]
    resources = ["*"]
  }
}
module {
  ...
  policy_document = data.aws_iam_policy_document.s3_reader.json
}

*/
