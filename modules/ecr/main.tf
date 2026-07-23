resource "aws_ecr_repository" "this" {
  force_delete = var.force_delete
  # wiz-scan ignore-line
  image_tag_mutability = var.image_tag_mutability
  name                 = var.name
  tags                 = var.tags

  image_scanning_configuration {
    scan_on_push = var.image_scanning_configuration.scan_on_push
  }

  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = var.image_tag_mutability_exclusion_filter
    content {
      filter      = image_tag_mutability_exclusion_filter.value.filter
      filter_type = image_tag_mutability_exclusion_filter.value.filter_type
    }
  }
}

resource "aws_ecr_lifecycle_policy" "custom_lifecycle_policy" {
  count = var.custom_lifecycle_policy != null && !var.enable_default_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = var.custom_lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "default_lifecycle_policy" {
  count = var.enable_default_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules : [
      {
        rulePriority : 1,
        description : "Keep last 30 images",
        selection : {
          tagStatus : "any",
          countType : "imageCountMoreThan",
          countNumber : 30
        },
        action : {
          type : "expire"
        }
      }
    ]
  })
}
