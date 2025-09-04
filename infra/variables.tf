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


variable "enable_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "enable_identity_pool" {
  description = "Whether to create Cognito identity pool"
  type        = bool
  default     = true
}
// AWS region to deploy resources into
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-3"
}
// Callback URLs for Cognito Hosted UI
variable "spa_callback_urls" {
  description = "List of allowed callback URLs for the SPA client"
  type        = list(string)
}
// Logout URLs for Cognito Hosted UI
variable "spa_logout_urls" {
  description = "List of allowed logout URLs for the SPA client"
  type        = list(string)
}