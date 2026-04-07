variable "name_prefix" {
  description = "Name prefix for the table"
  type        = string
}

variable "read_capacity" {
  description = "Provisioned read capacity units"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Provisioned write capacity units"
  type        = number
  default     = 5
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
