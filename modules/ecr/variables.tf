variable "name" {
  description = "ECR repository name"
  type        = string
}

variable "max_image_count" {
  description = "Number of most-recent images to retain (older images expire)"
  type        = number
  default     = 3
}

variable "force_delete" {
  description = "Allow ECR to be deleted even if it contains images"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
