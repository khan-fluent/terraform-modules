variable "name_prefix" {
  description = "Prefix for SNS topic and alarm names (e.g. 'devops-portfolio')"
  type        = string
}

variable "alert_email" {
  description = "Email address subscribed to the SNS alerts topic"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name (for the running-tasks alarm)"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name (for the running-tasks alarm)"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier. Set to empty string to skip RDS alarms."
  type        = string
  default     = ""
}

variable "autoscaling_group_name" {
  description = "EC2 ASG name (for the EC2 CPU alarm)"
  type        = string
}

variable "ec2_instance_id" {
  description = "EC2 instance ID (for the auto-recovery alarm)"
  type        = string
}

variable "aws_region" {
  description = "AWS region (used to construct EC2 recover action ARN)"
  type        = string
  default     = "us-east-1"
}

variable "ec2_cpu_threshold" {
  description = "EC2 CPU alarm threshold (percent)"
  type        = number
  default     = 80
}

variable "rds_cpu_threshold" {
  description = "RDS CPU alarm threshold (percent)"
  type        = number
  default     = 80
}

variable "rds_storage_threshold_bytes" {
  description = "RDS free storage alarm threshold (bytes)"
  type        = number
  default     = 2000000000
}

variable "rds_connections_threshold" {
  description = "RDS connections alarm threshold"
  type        = number
  default     = 50
}
