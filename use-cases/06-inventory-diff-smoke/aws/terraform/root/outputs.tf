output "vpc_id" {
  value       = aws_vpc.uc06.id
  description = "UC06 VPC id"
}

output "subnet_id" {
  value       = aws_subnet.uc06.id
  description = "UC06 subnet id"
}

output "security_group_id" {
  value       = aws_security_group.uc06.id
  description = "UC06 security group id"
}

