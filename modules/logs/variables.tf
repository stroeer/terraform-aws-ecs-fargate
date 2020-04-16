# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "domain_name" {
  description = "The name of an existing Elasticsearch domain used as destination for the Firehose delivery stream."
  type        = string
}

variable "service_name" {
  description = "Name of the service to collect log events for. This will be used as the Elasticsearch index name and for IAM configuration."
  type        = string
}

variable "task_role_name" {
  description = "Name of the IAM role used by the containers in a task. Firehose and CloudWatch Log policies will be attached to this role."
  type        = string
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

variable "firehose_delivery_stream_s3_backup_bucket_arn" {
  default     = ""
  description = "Use an existing S3 bucket to backup log documents which couldn't be streamed to Elasticsearch. Otherwise a separate bucket for this service will be created."
  type        = string
}

variable "fluentbit_cloudwatch_log_group_name" {
  default     = ""
  description = "Use an existing CloudWatch log group for storing logs of the fluent-bit sidecar. Otherwise a dedicate log group for this service will be created."
  type        = string
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the Kinesis Firehose resource."
  type        = map(string)
}
