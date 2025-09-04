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

variable "log_bucket_arn" {
  description = "ARN of S3 bucket for CloudFront logs (if logging enabled)"
  type        = string
  default     = ""
}
