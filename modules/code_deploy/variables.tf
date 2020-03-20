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

variable "use_code_deploy" {
  type = bool
}