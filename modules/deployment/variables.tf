variable "service_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "listener_arns" {
  type = list(string)
}

variable "create_deployment_pipeline" {
  type = bool
}

variable "task_role_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "ecr_repository_name" {
  type = string
}