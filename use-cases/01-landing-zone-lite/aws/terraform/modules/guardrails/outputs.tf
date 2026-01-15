output "alerts_topic_arn" {
  description = "ARN of the SNS topic that receives guardrail alerts"
  value       = try(aws_sns_topic.alerts[0].arn, null)
}

output "scp_policy_id" {
  description = "ID of the optional guardrail SCP"
  value       = try(aws_organizations_policy.guardrails[0].id, null)
}
