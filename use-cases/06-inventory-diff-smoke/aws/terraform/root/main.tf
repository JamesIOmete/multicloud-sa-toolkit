provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : format("mcsa-uc06-%s", var.env)

  tags = {
    toolkit    = "multicloud-sa-toolkit"
    use_case   = "06-inventory-diff-smoke"
    env        = var.env
    owner      = var.owner
    managed_by = "terraform"
  }
}

# A tiny, low-cost footprint that reliably shows up in UC02 counts:
# - 1 VPC
# - 1 Subnet
# - 1 Security Group
resource "aws_vpc" "uc06" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-vpc" })
}

resource "aws_subnet" "uc06" {
  vpc_id                  = aws_vpc.uc06.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = false

  tags = merge(local.tags, { Name = "${local.name_prefix}-subnet" })
}

resource "aws_security_group" "uc06" {
  name        = "${local.name_prefix}-sg"
  description = "UC06 test SG for inventory diffing (no ingress)"
  vpc_id      = aws_vpc.uc06.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-sg" })
}

