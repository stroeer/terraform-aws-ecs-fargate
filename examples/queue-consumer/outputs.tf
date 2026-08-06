output "queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.example.url
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "ecr_repository_url" {
  description = "The ECR repository URL for the queue consumer service"
  value       = module.queue_consumer_service.ecr_repository_url
}