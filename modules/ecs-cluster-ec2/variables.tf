variable "cluster_name" {
  description = "Name of the ECS cluster (also used as prefix for IAM roles, ASG, launch template)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EC2 ASG"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the EC2 instances"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "ASG min size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "ASG max size"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 1
}

variable "imdsv2_required" {
  description = "Require IMDSv2 on the launch template"
  type        = bool
  default     = false
}

variable "container_insights" {
  description = "Enable Container Insights on the cluster"
  type        = bool
  default     = false
}
