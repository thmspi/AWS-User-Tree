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
// pass in API endpoint and logout URL for SPA dashboard
variable "dashboard_api_endpoint" {
  description = "API endpoint URL for fetching the user tree"
  type        = string
}
variable "dashboard_logout_url" {
  description = "Logout URL for SPA dashboard"
  type        = string
}