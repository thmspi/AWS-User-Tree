# SPA hosting: S3 bucket + CloudFront + ACM + OAC

data "aws_caller_identity" "current" {}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "spa" {
  bucket = "${terraform.workspace}-${var.stack_id}-spa-${random_id.bucket_suffix.hex}"
  tags          = var.tags
  force_destroy = true
}

resource "aws_cloudfront_origin_access_control" "spa_oac" {
  name                               = "${terraform.workspace}-${var.stack_id}-spa-oac"
  description                        = "Origin Access Control for SPA bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                   = "always"
  signing_protocol                   = "sigv4"
}

resource "aws_cloudfront_distribution" "spa" {
  enabled             = true
  default_root_object = "index.html"
  tags                = var.tags

  origin {
    domain_name              = aws_s3_bucket.spa.bucket_regional_domain_name
    origin_id                = "spaS3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.spa_oac.id
  }

  default_cache_behavior {
    allowed_methods             = ["GET", "HEAD", "OPTIONS"]
    cached_methods              = ["GET", "HEAD"]
    target_origin_id            = "spaS3Origin"
    viewer_protocol_policy      = "redirect-to-https"
    cache_policy_id             = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    origin_request_policy_id    = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  dynamic "logging_config" {
    for_each = var.enable_logging && var.log_bucket_arn != "" ? [1] : []
    content {
      bucket         = var.log_bucket_arn
      include_cookies = false
      prefix          = "${var.stack_id}/"
    }
  }
}

resource "aws_s3_bucket_policy" "spa_policy" {
  bucket = aws_s3_bucket.spa.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.spa.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.spa.arn
        }
      }
    }]
  })
}

// Deploy SPA (index.html) from template
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.spa.id
  key          = "index.html"
  content      = templatefile(
    "${path.module}/../../web/index.html.tpl",
    { login_url = var.login_url }
  )
  content_type = "text/html"
  depends_on   = [aws_s3_bucket.spa]
}

output "spa_bucket_name" {
  value = aws_s3_bucket.spa.bucket
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.spa.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.spa.id
}