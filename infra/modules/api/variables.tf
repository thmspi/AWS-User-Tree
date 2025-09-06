variable "stack_id" {
  description = "Unique stack identifier"
  type        = string
}

variable "tags" {
  description = "Common tags map"
  type        = map(string)
}

variable "table_name" {
  description = "DynamoDB table name for user tree"
  type        = string
}
// DynamoDB table name for teams
variable "teams_table_name" {
  description = "DynamoDB table name for teams"
  type        = string
}
// AWS region for resource ARNs
variable "aws_region" {
  description = "AWS region"
  type        = string
}
// Cognito User Pool ID for registration functions
variable "user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}