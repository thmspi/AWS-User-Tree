variable "stack_id" {
  description = "Unique stack identifier"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
}

variable "admin_username" {
  description = "Username for the first (root) admin user"
  type        = string
}

variable "admin_password" {
  description = "Password for the first (root) admin user"
  type        = string
  sensitive   = true
}

variable "enable_identity_pool" {
  description = "Whether to create a Cognito identity pool"
  type        = bool
  default     = true
}

variable "spa_callback_urls" {
  description = "List of allowed callback URLs for the SPA client"
  type        = list(string)
}

variable "spa_logout_urls" {
  description = "List of allowed logout URLs for the SPA client"
  type        = list(string)
}