output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "spa_client_id" {
  value = aws_cognito_user_pool_client.spa.id
}

output "cognito_domain" {
  value = aws_cognito_user_pool_domain.this.domain
}
