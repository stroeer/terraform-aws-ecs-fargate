# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "service_name" {
  description = "Name of the service to collect log events for. This will be used as the Elasticsearch index name and for IAM configuration."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "domain_name" {
  default     = "application-logs"
  description = "The name of an existing Elasticsearch domain used as destination for the Firehose delivery stream."
}

variable "enabled" {
  default     = true
  description = "Conditionally enables this module (and all it's ressources)."
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the Kinesis Firehose resource."
  type        = map(string)
}
