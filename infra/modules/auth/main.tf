# Cognito pools, groups, roles

resource "aws_cognito_user_pool" "this" {
  name                        = "${terraform.workspace}-${var.stack_id}-user-pool"
  auto_verified_attributes    = ["email"]
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
  schema {
    name              = "email"
    attribute_data_type = "String"
    required          = true
  }
}

resource "aws_cognito_user_pool_client" "spa" {
  name                              = "${terraform.workspace}-${var.stack_id}-spa-client"
  user_pool_id                      = aws_cognito_user_pool.this.id
  generate_secret                   = false
  allowed_oauth_flows               = ["implicit"]
  allowed_oauth_scopes              = ["openid", "email", "profile"]
  callback_urls                     = var.spa_callback_urls
  logout_urls                       = var.spa_logout_urls
  supported_identity_providers      = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  explicit_auth_flows                  = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_cognito_user" "admin" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = var.admin_username
  attributes = {
    email = var.admin_username
  }
  password             = var.admin_password
  message_action       = "SUPPRESS"
  force_alias_creation = true
}


resource "aws_cognito_user_group" "employees" {
  user_pool_id = aws_cognito_user_pool.this.id
  name         = "${terraform.workspace}-${var.stack_id}-employees"
  description  = "Read-only employees"
  precedence   = 10
}

resource "aws_cognito_user_group" "managers" {
  user_pool_id = aws_cognito_user_pool.this.id
  name         = "${terraform.workspace}-${var.stack_id}-managers"
  description  = "Administrators of employee hierarchy"
  precedence   = 5
}

resource "aws_cognito_user_in_group" "admin_manager" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = aws_cognito_user.admin.username
  group_name   = aws_cognito_user_group.managers.name
}

# Hosted UI Domain for Cognito
resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${terraform.workspace}-${var.stack_id}"
  user_pool_id = aws_cognito_user_pool.this.id
}

// Identity Pool and Roles
// region for provider names
data "aws_region" "current" {}
resource "aws_cognito_identity_pool" "this" {
  count                          = var.enable_identity_pool ? 1 : 0
  identity_pool_name             = "${terraform.workspace}-${var.stack_id}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.spa.id
    provider_name           = "cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"
    server_side_token_check = true
  }
}

resource "aws_iam_role" "authenticated" {
  count = var.enable_identity_pool ? 1 : 0
  name  = "${terraform.workspace}-${var.stack_id}-authenticated-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Federated = "cognito-identity.amazonaws.com" }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.this[0].id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "auth_session_tags" {
  count = var.enable_identity_pool ? 1 : 0
  name  = "${terraform.workspace}-${var.stack_id}-auth-tags"
  role  = aws_iam_role.authenticated[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sts:TagSession"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "this" {
  count                 = var.enable_identity_pool ? 1 : 0
  identity_pool_id      = aws_cognito_identity_pool.this[0].id
  roles = {
    authenticated = aws_iam_role.authenticated[0].arn
  }
}