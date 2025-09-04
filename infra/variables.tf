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
  default     = "us-west-3"
}