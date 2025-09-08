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