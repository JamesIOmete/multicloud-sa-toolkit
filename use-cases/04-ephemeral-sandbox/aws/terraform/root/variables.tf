variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-west-2"
}

variable "env" {
  type        = string
  description = "Environment identifier"
  default     = "toolkit-test"
}

variable "owner" {
  type        = string
  description = "Owner tag"
  default     = "platform-team"
}

variable "sandbox_id" {
  type        = string
  description = "Unique sandbox identifier"
  default     = "dev01"
}

variable "name_prefix" {
  type        = string
  description = "Optional name prefix override"
  default     = ""
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags merged into defaults"
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for sandbox VPC"
  default     = "10.24.0.0/20"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for public subnets"
  default     = ["10.24.0.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for private subnets"
  default     = ["10.24.1.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones to use"
  default     = ["us-west-2a"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Provision NAT gateway"
  default     = false
}

variable "container_image" {
  type        = string
  description = "Container image for Fargate"
  default     = "public.ecr.aws/docker/library/httpd:2.4-alpine"
}

variable "container_port" {
  type        = number
  description = "Container/listener port"
  default     = 80
}

variable "desired_count" {
  type        = number
  description = "Desired ECS tasks"
  default     = 1
}

variable "task_cpu" {
  type        = number
  description = "Fargate task CPU units"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Fargate task memory"
  default     = 512
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable ECS Container Insights"
  default     = true
}

variable "task_log_retention_days" {
  type        = number
  description = "Retention for ECS logs"
  default     = 14
}

variable "monthly_budget_amount" {
  type        = number
  description = "Monthly cost ceiling"
  default     = 25
}

variable "budget_threshold_percent" {
  type        = number
  description = "Budget forecast threshold"
  default     = 80
}

variable "anomaly_threshold_amount" {
  type        = number
  description = "Anomaly detection threshold (USD)"
  default     = 10
}

variable "enable_cost_anomaly_monitor" {
  type        = bool
  description = "Create Cost Explorer anomaly monitor"
  default     = false
}

variable "alert_topic_arn" {
  type        = string
  description = "Existing SNS topic ARN to notify"
  default     = ""
}

variable "fallback_alert_topic_arn" {
  type        = string
  description = "Fallback SNS topic ARN (e.g., UC01 alerts)"
  default     = "arn:aws:sns:us-west-2:<ACCOUNT_ID>:mcsa-uc01-toolkit-test-alerts"
}

variable "metadata_table_name" {
  type        = string
  description = "Existing metadata table name"
  default     = ""
}

variable "create_metadata_table" {
  type        = bool
  description = "Create metadata table"
  default     = true
}

variable "ttl_hours" {
  type        = number
  description = "Sandbox TTL in hours"
  default     = 72
}
