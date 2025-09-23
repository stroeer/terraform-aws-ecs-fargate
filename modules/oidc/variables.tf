variable "ecr_name" {
  description = "The name of the AWS ECR repository."
  type        = string
  default     = ""
}

variable "gh_repo_name" {
  description = "The name of github repository including the organisation (like stroeer/some-repo)."
  type        = string
  default     = ""
}

variable "gh_refs" {
  description = "A list of refs that are allowed to push images to the ecr repository."
  type        = list(string)
  default     = ["main"]
}