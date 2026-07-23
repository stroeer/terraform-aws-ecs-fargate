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
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE, IMMUTABLE, MUTABLE_WITH_EXCLUSION or IMMUTABLE_WITH_EXCLUSION. Defaults to MUTABLE."
  type        = string
  validation {
    condition = contains(
      ["MUTABLE", "IMMUTABLE", "IMMUTABLE_WITH_EXCLUSION", "MUTABLE_WITH_EXCLUSION"],
      var.image_tag_mutability
    )
    error_message = "Must be one of MUTABLE, IMMUTABLE, IMMUTABLE_WITH_EXCLUSION, MUTABLE_WITH_EXCLUSION"
  }
}

variable "image_tag_mutability_exclusion_filter" {
  default = []
  type = list(object({
    filter      = string
    filter_type = string
  }))
  description = "Tag immutability exclusion filters. Only applicable when image_tag_mutability is in (IMMUTABLE_WITH_EXCLUSION, MUTABLE_WITH_EXCLUSION). All filter must must contain only letters, numbers, and special characters (._-), be up to 128 characters long and can contain a maximum of 2 wildcards. All filter_type must be WILDCARD."
  validation {
    condition = (length(var.image_tag_mutability_exclusion_filter) == 0 || contains(["MUTABLE_WITH_EXCLUSION", "IMMUTABLE_WITH_EXCLUSION"], var.image_tag_mutability)) && alltrue(
      [for ief in var.image_tag_mutability_exclusion_filter : (ief.filter_type == "WILDCARD")]
    )
    error_message = "Only applicable when image_tag_mutability in (MUTABLE_WITH_EXCLUSION, IMMUTABLE_WITH_EXCLUSION)"
  }
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
