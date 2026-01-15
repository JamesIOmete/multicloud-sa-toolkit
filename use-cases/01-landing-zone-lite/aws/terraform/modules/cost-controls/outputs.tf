output "alerts_topic_arn" {
  description = "SNS topic ARN used for cost alerts"
  value       = try(aws_sns_topic.alerts[0].arn, null)
}

output "budget_id" {
  description = "ID of the AWS monthly budget"
  value       = try(aws_budgets_budget.monthly[0].id, null)
}

output "anomaly_subscription_arn" {
  description = "ARN of the cost anomaly subscription"
  value       = try(aws_ce_anomaly_subscription.account[0].arn, null)
}
