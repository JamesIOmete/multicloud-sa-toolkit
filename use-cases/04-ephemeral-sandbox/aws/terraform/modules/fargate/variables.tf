variable "base_name" {
  type        = string
  description = "Base name for resources"
}

variable "sandbox_id" {
  type        = string
  description = "Unique sandbox identifier"
}

variable "env" {
  type        = string
  description = "Environment tag"
}

variable "owner" {
  type        = string
  description = "Owner tag"
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags merged into defaults"
  default     = {}
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC identifier"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID for service"
}

variable "container_image" {
  type        = string
  description = "Container image for token workload"
  default     = "public.ecr.aws/docker/library/httpd:2.4-alpine"
}

variable "container_port" {
  type        = number
  description = "Container/listener port exposed by the workload"
  default     = 80
}

variable "desired_count" {
  type        = number
  description = "Number of desired tasks"
  default     = 1
}

variable "task_cpu" {
  type        = number
  description = "Fargate task CPU units"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Fargate task memory (MiB)"
  default     = 512
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable ECS CloudWatch Container Insights"
  default     = true
}

variable "log_retention_days" {
  type        = number
  description = "Log retention for task log group"
  default     = 14
}
