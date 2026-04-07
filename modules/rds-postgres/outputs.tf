output "db_host" {
  description = "RDS instance address"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS instance port (string)"
  value       = tostring(aws_db_instance.this.port)
}

output "db_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the master password"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
