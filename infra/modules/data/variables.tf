variable "stack_id" {
  description = "Unique stack identifier (e.g., dev, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags map"
  type        = map(string)
}

variable "admin_username" {
  description = "Username for the root admin user"
  type        = string
}
