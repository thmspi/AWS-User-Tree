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

// Seed the root admin user as the top of the tree
resource "aws_dynamodb_table_item" "admin" {
  table_name = aws_dynamodb_table.user_tree.name
  hash_key   = "username"
  # Seed the root admin user to match CSV configuration
  item = jsonencode({
    username    = { S = "thomas@thomas.com" }
    given_name  = { S = "Thomas" }
    family_name = { S = "Picou" }
    level       = { N = "0" }
    children    = { L = [
      { S = "manon@chemla.com" },
      { S = "antoine@picou.com" },
      { S = "Employe1@Employe.com" }
    ] }
    team        = { L = [] }
    job         = { L = [{ S = "Administrator" }] }
    permissions = { L = [] }
    is_manager  = { BOOL = true }
    manager     = { S = "" }
  })
  depends_on = [aws_dynamodb_table.user_tree]
}

# Seed additional users from selected.csv
resource "aws_dynamodb_table_item" "manon_chemla_com" {
  table_name = aws_dynamodb_table.user_tree.name
  hash_key   = "username"
  item = jsonencode({
    username    = { S = "manon@chemla.com" }
    given_name  = { S = "Manon" }
    family_name = { S = "Chemla" }
    level       = { N = "1" }
    children    = { L = [{ S = "eric@picou.com" }, { S = "Employe2@Employe2.com" }] }
    team        = { L = [{ S = "Cloud" }] }
    job         = { L = [{ S = "Tourisme" }] }
    permissions = { L = [] }
    is_manager  = { BOOL = true }
    manager     = { S = "amiscremail@gmail.com" }
  })
  depends_on = [aws_dynamodb_table.user_tree]
}

resource "aws_dynamodb_table_item" "employe1_employe_com" {
  table_name = aws_dynamodb_table.user_tree.name
  hash_key   = "username"
  item = jsonencode({
    username    = { S = "Employe1@Employe.com" }
    given_name  = { S = "Employé 1" }
    family_name = { S = "" }
    level       = { N = "1" }
    children    = { L = [] }
    team        = { L = [{ S = "Cloud" }] }
    job         = { L = [{ S = "Employe" }] }
    permissions = { L = [] }
    is_manager  = { BOOL = false }
    manager     = { S = "thomas@thomas.com" }
  })
  depends_on = [aws_dynamodb_table.user_tree]
}

resource "aws_dynamodb_table_item" "employe2_employe2_com" {
  table_name = aws_dynamodb_table.user_tree.name
  hash_key   = "username"
  item = jsonencode({
    username    = { S = "Employe2@Employe2.com" }
    given_name  = { S = "Employe 2" }
    family_name = { S = "" }
    level       = { N = "1" }
    children    = { L = [] }
    team        = { L = [{ S = "Cloud" }] }
    job         = { L = [{ S = "Employe" }] }
    permissions = { L = [] }
    is_manager  = { BOOL = false }
    manager     = { S = "manon@chemla.com" }
  })
  depends_on = [aws_dynamodb_table.user_tree]
}

resource "aws_dynamodb_table_item" "antoine_picou_com" {
  table_name = aws_dynamodb_table.user_tree.name
  hash_key   = "username"
  item = jsonencode({
    username    = { S = "antoine@picou.com" }
    given_name  = { S = "Antoine" }
    family_name = { S = "Picou" }
    level       = { N = "1" }
    children    = { L = [] }
    team        = { L = [{ S = "Cloud" }] }
    job         = { L = [{ S = "Student" }] }
    permissions = { L = [] }
    is_manager  = { BOOL = true }
    manager     = { S = "thomas@thomas.com" }
  })
  depends_on = [aws_dynamodb_table.user_tree]

}

resource "aws_dynamodb_table_item" "eric_picou_com" {
  table_name = aws_dynamodb_table.user_tree.name
  hash_key   = "username"
  item = jsonencode({
    username    = { S = "eric@picou.com" }
    given_name  = { S = "Eric" }
    family_name = { S = "Picou" }
    level       = { N = "1" }
    children    = { L = [{ S = "Employe3@Employe3.com" }] }
    team        = { L = [{ S = "Cloud" }] }
    job         = { L = [{ S = "Cloud" }] }
    permissions = { L = [] }
    is_manager  = { BOOL = true }
    manager     = { S = "manon@chemla.com" }
  })
  depends_on = [aws_dynamodb_table.user_tree]
}

resource "aws_dynamodb_table_item" "employe3_employe3_com" {
  table_name = aws_dynamodb_table.user_tree.name
  hash_key   = "username"
  item = jsonencode({
    username    = { S = "Employe3@Employe3.com" }
    given_name  = { S = "Employe3" }
    family_name = { S = "" }
    level       = { N = "1" }
    children    = { L = [] }
    team        = { L = [{ S = "Cloud" }] }
    job         = { L = [{ S = "Employe3" }] }
    permissions = { L = [] }
    is_manager  = { BOOL = false }
    manager     = { S = "eric@picou.com" }
  })
  depends_on = [aws_dynamodb_table.user_tree]
}