output "target_groups" {
  value = flatten(list(aws_alb_target_group.blue.*.arn, aws_alb_target_group.green.*.arn))
}
