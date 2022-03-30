resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability #tfsec:ignore:aws-ecr-enforce-immutable-repository
  tags                 = var.tags

  image_scanning_configuration {
    scan_on_push = var.image_scanning_configuration.scan_on_push
  }
}
