variable "name_prefix" {
  description = "Prefix for security group names (e.g. 'devops-portfolio')"
  type        = string
}

variable "web_ingress" {
  description = "List of ingress rules for the web security group: [{description, port}]"
  type = list(object({
    description = string
    port        = number
  }))
  default = [
    { description = "App", port = 3000 }
  ]
}

variable "web_description" {
  description = "Description for the web security group"
  type        = string
  default     = "Allow app port inbound traffic"
}

variable "create_rds_sg" {
  description = "Whether to create the RDS security group"
  type        = bool
  default     = true
}
