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
// AWS region for resource ARNs
variable "aws_region" {
  description = "AWS region"
  type        = string
}