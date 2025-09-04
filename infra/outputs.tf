// Root outputs
output "cloudfront_domain" {
  value = module.hosting.cloudfront_domain
}

output "spa_bucket_name" {
  value = module.hosting.bucket_name
}

output "user_pool_id" {
  value = module.auth.user_pool_id
}

output "spa_client_id" {
  value = module.auth.spa_client_id
}