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
// Admin user's first name (given name)
variable "admin_given_name" {
  description = "First name for the root admin user"
  type        = string
}
// Admin user's family name (last name)
variable "admin_family_name" {
  description = "Last name for the root admin user"
  type        = string
}
