variable "service_name" {
  description = "Name used for the ECS service, task family, container name, IAM roles, and log group"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID or ARN to deploy the service into"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the container image (the `:latest` tag is appended)"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "task_cpu" {
  description = "CPU units at the task definition level. Leave null to omit."
  type        = number
  default     = null
}

variable "task_memory" {
  description = "Memory (MiB) at the task definition level. Leave null to omit."
  type        = number
  default     = null
}

variable "container_cpu" {
  description = "CPU units at the container level"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory (MiB) at the container level"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of running tasks"
  type        = number
  default     = 1
}

variable "network_mode" {
  description = "Task network mode (host or awsvpc)"
  type        = string
  default     = "host"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "environment" {
  description = "List of environment variables for the container [{name, value}]"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "List of secrets injected into the container [{name, valueFrom}]"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "execution_role_secretsmanager_arns" {
  description = "Secrets Manager secret ARNs the execution role needs to read"
  type        = list(string)
  default     = []
}

variable "execution_role_ssm_parameter_arns" {
  description = "SSM parameter ARNs the execution role needs to read"
  type        = list(string)
  default     = []
}

variable "task_role_inline_policies" {
  description = "Map of inline policy name -> JSON policy document for the task (application) role"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
