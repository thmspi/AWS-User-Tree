variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
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
// AWS region for template context
variable "region" {
  description = "AWS region, passed into templates"
  type        = string
}
// Cognito User Pool ID for in-template verification
variable "user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}
// Cognito App Client ID
variable "client_id" {
  description = "Cognito App Client ID"
  type        = string
}