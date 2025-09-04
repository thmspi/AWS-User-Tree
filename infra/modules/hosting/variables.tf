variable "stack_id" {
  description = "Unique stack identifier (e.g., dev, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
}


variable "enable_logging" {
  description = "Enable CloudFront access logs"
  type        = bool
  default     = false
}

variable "log_bucket_allow_acl" {
  description = "Whether to allow ACLs on the CloudFront log bucket. Set to true only if your account/organization allows ACLs. If false, logging to S3 is disabled to avoid ACL errors."
  type        = bool
  default     = true
}

