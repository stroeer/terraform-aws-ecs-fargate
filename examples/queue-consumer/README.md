# Queue Consumer Example

This example demonstrates how to use the terraform-aws-ecs-fargate module to create an ECS Fargate service that doesn't expose any ports. This is ideal for applications that:

- Process messages from SQS queues
- Consume data from Kinesis streams
- Process DynamoDB streams
- Run scheduled/batch jobs
- Perform background processing tasks

## Key Features

- **No exposed ports**: The service doesn't expose any HTTP/TCP ports since it only processes queue messages
- **Minimal security**: No ingress security group needed since no external traffic is expected
- **IAM permissions**: Includes proper IAM policy for accessing SQS queue
- **Private networking**: Runs in private subnets with NAT gateway for outbound internet access

## Resources Created

- ECS Fargate service without exposed ports
- SQS queue for message processing
- VPC with private subnets
- ECR repository for container images
- IAM roles and policies for SQS access
- CloudWatch log group for container logs

## Usage

```bash
terraform init
terraform plan
terraform apply
```

After deployment, you can:
1. Push your queue consumer container image to the ECR repository
2. Send messages to the SQS queue
3. Monitor the service logs in CloudWatch

## Clean Up

```bash
terraform destroy
```

Note: Make sure to empty the ECR repository before running destroy if you've pushed images to it.