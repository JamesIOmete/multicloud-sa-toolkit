output "queue_name" {
  value       = aws_sqs_queue.app_queue.name
  description = "Token workload SQS queue name"
}

output "queue_arn" {
  value       = aws_sqs_queue.app_queue.arn
  description = "Token workload SQS queue ARN"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.app_logs.name
  description = "CloudWatch log group for token workload"
}
