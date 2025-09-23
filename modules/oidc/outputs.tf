output "github_oidc_ecr_access_arn" {
  description = "The ARN to access the ecr via github oidc."
  value       = aws_iam_role.ecr_access.arn
}

output "github_oidc_ecr_access_name" {
  description = "The ARN to access the ecr via github oidc."
  value       = aws_iam_role.ecr_access.name
}