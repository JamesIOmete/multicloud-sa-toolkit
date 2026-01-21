output "alb_dns_name" {
  value       = aws_lb.sandbox.dns_name
  description = "Public DNS name of the sandbox ALB"
}

output "service_name" {
  value       = aws_ecs_service.sandbox.name
  description = "Name of the ECS service"
}

output "cluster_name" {
  value       = aws_ecs_cluster.sandbox.name
  description = "ECS cluster name"
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.sandbox.arn
  description = "ARN of the ECS task definition"
}

output "execution_role_arn" {
  value       = aws_iam_role.task_execution.arn
  description = "ARN of the ECS task execution role"
}
