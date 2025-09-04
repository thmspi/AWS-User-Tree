output "user_tree_table_name" {
  description = "Name of the DynamoDB table for the user tree"
  value       = aws_dynamodb_table.user_tree.name
}
