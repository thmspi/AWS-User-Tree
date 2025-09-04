// Root outputs
output "cloudfront_domain" {
  value = "https://${module.hosting.cloudfront_domain}"
}

output "user_pool_id" {
  value = module.auth.user_pool_id
}

output "spa_client_id" {
  value = module.auth.spa_client_id
}

output "dashboard_url" {
  value = module.hosting.dashboard_url
}