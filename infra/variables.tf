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

// Admin user's first name (given name)
variable "admin_given_name" {
  description = "First name for the root admin user"
  type        = string
}

// Admin user's last name (family name)
variable "admin_family_name" {
  description = "Last name for the root admin user"
  type        = string
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
