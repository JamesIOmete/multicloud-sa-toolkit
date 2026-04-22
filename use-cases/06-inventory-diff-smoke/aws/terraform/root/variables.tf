variable "env" {
  description = "Environment name used in naming and tagging"
  type        = string
  default     = "toolkit-test"
}

variable "owner" {
  description = "Owner tag value for resources"
  type        = string
  default     = "platform-team"
}

variable "name_prefix" {
  description = "Override for the default mcsa-uc06-<env> prefix"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the test VPC"
  type        = string
  default     = "10.250.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the test subnet"
  type        = string
  default     = "10.250.10.0/24"
}

