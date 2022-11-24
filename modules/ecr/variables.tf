# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "Name of the repository."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "image_scanning_configuration" {
  description = "Configuration block that defines image scanning configuration for the repository. By default, image scanning must be manually triggered. See the ECR User Guide for more information about image scanning."
  type = object({
    scan_on_push = bool,
  })

  default = {
    scan_on_push = true
  }
}

variable "image_tag_mutability" {
  default     = "MUTABLE"
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE. Defaults to MUTABLE."
  type        = string
}

variable "custom_lifecycle_policy" {
  default     = null
  description = "json policy for aws_ecr_lifecycle_policy"
  type        = string
}

variable "enable_default_lifecycle_policy" {
  default     = false
  description = "Expires all images excepct for the last 30."
  type        = bool
}

variable "force_delete" {
  default     = false
  description = "If `true`, will delete this repository even if it contains images."
  type        = bool
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the repository."
  type        = map(string)
}
