# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "elasticsearch_domain_arn" {
  description = "Amazon Resource Name (ARN) of an existing Elasticsearch domain. IAM permissions for sending logs to this domain will be added."
  type        = string
}

variable "service_name" {
  description = "Name of the service to collect log events for. This will be used as the Elasticsearch index name and for IAM configuration."
  type        = string
}

variable "task_role_name" {
  description = "Name of the IAM role used by the containers in this service. IAM permissions for sending logs to Elasticsearch will be added to this role."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "fluentbit_cloudwatch_log_group_name" {
  default     = ""
  description = "Use an existing CloudWatch log group for storing logs of the fluent-bit sidecar. Otherwise a dedicate log group for this service will be created."
  type        = string
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the created resources."
  type        = map(string)
}
