output "ecr_repo_ids" {
  value = aws_ecr_repository.this.id
}

output "public_dns" {
  value = "${aws_route53_record.external.name}.${data.aws_route53_zone.external.name}"
}

output "private_dns" {
  value = "${aws_route53_record.internal.name}.${data.aws_route53_zone.internal.name}"
}