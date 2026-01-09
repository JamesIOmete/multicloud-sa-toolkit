variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "name_prefix" {
  type    = string
  default = "multicloud-sa-toolkit-tfstate"
}

variable "dynamodb_table_name" {
  type    = string
  default = "terraform-state-locks"
}
