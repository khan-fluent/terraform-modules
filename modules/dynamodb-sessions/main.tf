resource "aws_dynamodb_table" "this" {
  name         = "${var.name_prefix}-sessions"
  billing_mode = "PROVISIONED"

  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity

  hash_key  = "userId"
  range_key = "sessionId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "sessionId"
    type = "S"
  }

  attribute {
    name = "updatedAt"
    type = "S"
  }

  global_secondary_index {
    name            = "byUpdatedAt"
    hash_key        = "userId"
    range_key       = "updatedAt"
    projection_type = "ALL"
    read_capacity   = var.read_capacity
    write_capacity  = var.write_capacity
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  tags = var.tags
}
