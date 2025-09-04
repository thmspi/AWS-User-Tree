variable "stack_id" {
  description = "Unique stack identifier (e.g. dev, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags map"
  type        = map(string)
}

variable "admin_username" {
  description = "Root Cognito user email/username"
  type        = string
}

variable "admin_password" {
  description = "Root Cognito user password"
  type        = string
  sensitive   = true
}

variable "spa_callback_urls" {
  description = "List of allowed callback URLs for SPA"
  type        = list(string)
}

variable "spa_logout_urls" {
  description = "List of allowed logout URLs for SPA"
  type        = list(string)
}


variable "enable_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "log_bucket_arn" {
  description = "S3 ARN for CloudFront logs"
  type        = string
  default     = ""
}

variable "enable_identity_pool" {
  description = "Whether to create Cognito identity pool"
  type        = bool
  default     = true
}