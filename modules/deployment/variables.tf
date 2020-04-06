# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "ecr_repository_name" {
  type = string
}

variable "health_check_path" {
  type = string
}

variable "service_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "listener_arns" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "task_role_arn" {
  type = string
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
