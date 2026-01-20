output "monitoring_topic_arn" {
  value       = local.topic_arn
  description = "SNS topic ARN used for monitoring alerts"
}

output "dashboard_name" {
  value       = module.alarms.dashboard_name
  description = "CloudWatch dashboard name"
}

output "queue_name" {
  value       = module.token_workloads.queue_name
  description = "Token workload SQS queue name"
}

output "queue_arn" {
  value       = module.token_workloads.queue_arn
  description = "Token workload SQS queue ARN"
}

output "log_group_name" {
  value       = module.token_workloads.log_group_name
  description = "CloudWatch log group provisioned for token workload"
}
