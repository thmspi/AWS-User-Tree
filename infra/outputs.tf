// Root outputs
output "cloudfront_domain" {
  value = "https://${module.hosting.cloudfront_domain}"
}