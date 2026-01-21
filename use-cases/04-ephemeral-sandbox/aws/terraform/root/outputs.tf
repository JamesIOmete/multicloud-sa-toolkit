output "sandbox_vpc_id" {
  description = "Sandbox VPC ID"
  value       = module.networking.vpc_id
}

output "sandbox_public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "sandbox_private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "alb_dns_name" {
  description = "Public DNS for sandbox ALB"
  value       = module.fargate.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.fargate.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.fargate.service_name
}

output "execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = module.fargate.execution_role_arn
}

output "metadata_table_name" {
  description = "DynamoDB metadata table name"
  value       = module.metadata.metadata_table_name
}

output "budget_id" {
  description = "AWS budget identifier"
  value       = module.cost_controls.budget_id
}

output "anomaly_subscription_arn" {
  description = "Cost Explorer anomaly subscription ARN"
  value       = module.cost_controls.anomaly_subscription_arn
}
