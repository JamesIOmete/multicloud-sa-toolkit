output "log_bucket_name" {
  description = "Name of the S3 bucket storing audit logs"
  value       = var.enable_logging ? try(module.logging[0].log_bucket_name, null) : null
}

output "guardrail_alert_topic_arn" {
  description = "SNS topic ARN for guardrail alerts"
  value       = var.enable_guardrails ? try(module.guardrails[0].alerts_topic_arn, null) : null
}

output "cost_alert_topic_arn" {
  description = "SNS topic ARN for cost alerts"
  value       = var.enable_cost_controls ? try(module.cost_controls[0].alerts_topic_arn, null) : null
}
