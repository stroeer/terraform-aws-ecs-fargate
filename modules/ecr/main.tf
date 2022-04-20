resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability #tfsec:ignore:aws-ecr-enforce-immutable-repository
  tags                 = var.tags

  image_scanning_configuration {
    scan_on_push = var.image_scanning_configuration.scan_on_push
  }
}

resource "aws_ecr_lifecycle_policy" "custom_lifecycle_policy" {
  count      = var.custom_lifecycle_policy == null ? 0 : 1
  repository = var.name

  policy = var.custom_lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "default_lifecycle_policy" {
  count      = var.enable_default_lifecycle_policy ? 0 : 1
  repository = var.name

  policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep last 30 images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 30
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
}
