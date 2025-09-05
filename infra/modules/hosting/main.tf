# SPA hosting: S3 bucket + CloudFront + ACM + OAC

data "aws_caller_identity" "current" {}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
resource "random_id" "log_bucket_suffix" {
  count       = var.enable_logging ? 1 : 0
  byte_length = 4
}

resource "aws_s3_bucket" "spa" {
  bucket        = "${terraform.workspace}-${var.stack_id}-spa-${random_id.bucket_suffix.hex}"
  tags          = var.tags
  force_destroy = true
}

// Log bucket for CloudFront access logs
resource "aws_s3_bucket" "log" {
  count  = var.enable_logging ? 1 : 0
  bucket = "${terraform.workspace}-${var.stack_id}-spa-logs-${random_id.log_bucket_suffix[0].hex}"
  tags   = var.tags
}

resource "aws_s3_bucket_ownership_controls" "spa" {
  bucket = aws_s3_bucket.spa.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "log" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.log[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_policy" "log_policy" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.log[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}



# Enable versioning on the log bucket
resource "aws_s3_bucket_versioning" "log" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.log[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Apply server-side encryption to the log bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.log[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "spa_oac" {
  name                              = "${terraform.workspace}-${var.stack_id}-spa-oac"
  description                       = "Origin Access Control for SPA bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
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
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "spaS3Origin"
    viewer_protocol_policy   = "redirect-to-https"
    # zero TTL in dev to always fetch fresh HTML
    min_ttl     = var.stack_id == "dev" ? 0 : 0
    default_ttl = var.stack_id == "dev" ? 0 : 86400
    max_ttl     = var.stack_id == "dev" ? 0 : 31536000
    # required when not using cache_policy_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}

resource "aws_s3_bucket_policy" "spa_policy" {
  bucket = aws_s3_bucket.spa.id
  policy = jsonencode({
    Version = "2012-10-17"
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

# Upload and deploy dashboard HTML with auto-invalidation
resource "aws_s3_object" "dashboard_html" {
  bucket        = aws_s3_bucket.spa.bucket
  key           = "dashboard.html"
  content       = templatefile(
                    "${path.module}/../../web/dashboard.html.tpl",
                    {
                      api_endpoint = var.dashboard_api_endpoint,
                      logout_url   = var.dashboard_logout_url
                    }
                  )
  content_type  = "text/html"
  cache_control = "max-age=31536000"
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