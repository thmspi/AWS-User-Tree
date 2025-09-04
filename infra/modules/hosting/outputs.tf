output "bucket_name" {
  value = aws_s3_bucket.spa.bucket
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.spa.domain_name
}

output "oac_id" {
  value = aws_cloudfront_origin_access_control.spa_oac.id
}
output "dashboard_url" {
  description = "CloudFront URL for dashboard page"
  value       = "https://${aws_cloudfront_distribution.spa.domain_name}/dashboard.html"
}