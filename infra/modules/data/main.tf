// DynamoDB table for user tree storage
resource "aws_dynamodb_table" "user_tree" {
  name         = "${terraform.workspace}-${var.stack_id}-user-tree"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"

  attribute {
    name = "username"
    type = "S"
  }

  tags = var.tags
}

// Seed the root admin user as the top of the tree
resource "aws_dynamodb_table_item" "admin" {
  table_name = aws_dynamodb_table.user_tree.name
  hash_key   = "username"
  # Seed the root admin user with full attribute set
  item = jsonencode({
    username     = { S    = var.admin_username }
    given_name   = { S    = var.admin_given_name }
    family_name  = { S    = var.admin_family_name }
    level        = { N    = "0" }
    groups       = { L    = [] }
    projects     = { L    = [] }
    permissions  = { L    = [] }
    manager      = { NULL = true }
  })
  depends_on = [aws_dynamodb_table.user_tree]
}