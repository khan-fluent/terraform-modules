output "vpc_id" {
  description = "ID of the default VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "IDs of default subnets"
  value       = data.aws_subnets.default.ids
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group (null if create_rds_sg = false)"
  value       = var.create_rds_sg ? aws_security_group.rds[0].id : null
}
