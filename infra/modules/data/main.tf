// DynamoDB table for user tree storage
resource "aws_dynamodb_table" "user_tree" {
  name         = "${terraform.workspace}-user-tree"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"

  attribute {
    name = "username"
    type = "S"
  }

  tags = var.tags
}
// DynamoDB table for user teams
resource "aws_dynamodb_table" "teams" {
  name         = "${terraform.workspace}-teams"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "team_id"

  attribute {
    name = "team_id"
    type = "S"
  }

  tags = var.tags
}

resource "aws_dynamodb_table_item" "admin" {
  table_name = aws_dynamodb_table.user_tree.name
  hash_key   = "username"
  item = jsonencode({
    username    = { S = "ceo@mail.com" }
    given_name  = { S = "My" }
    family_name = { S = "CEO" }
    level       = { N = "0" }
    children    = { L = [] }
    team        = { L = [] }
    job         = { L = [{ S = "CEO" }] }
    permissions = { L = [] }
    is_manager  = { BOOL = true }
    manager     = { S = "" }
  })
  depends_on = [aws_dynamodb_table.user_tree]
  lifecycle {
    ignore_changes = [item]
  }
}
