output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.this.arn
}

output "gsi_arn" {
  description = "DynamoDB byUpdatedAt GSI ARN"
  value       = "${aws_dynamodb_table.this.arn}/index/byUpdatedAt"
}
