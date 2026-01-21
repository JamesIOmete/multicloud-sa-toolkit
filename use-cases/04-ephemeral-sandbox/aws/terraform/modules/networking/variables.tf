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

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for sandbox VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones to use"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Provision NAT gateway for private subnets"
  default     = false
}
