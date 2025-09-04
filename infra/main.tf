terraform {

  backend "remote" {
    organization = "AWS-Users-Tree"
    workspaces {
      name = "dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}
// Configure AWS provider with region variable
provider "aws" {
  region = var.aws_region
}

// Instantiate Hosting module (S3 + CloudFront + OAC)
module "hosting" {
  source           = "./modules/hosting"
  stack_id         = var.stack_id
  tags             = var.tags
  enable_logging   = var.enable_logging
}

// Instantiate Auth module (Cognito User + Identity Pools)
module "auth" {
  source               = "./modules/auth"
  stack_id             = var.stack_id
  tags                 = var.tags
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  enable_identity_pool = var.enable_identity_pool
  spa_callback_urls    = ["https://${module.hosting.cloudfront_domain}/dashboard.html"]
  spa_logout_urls      = ["https://${module.hosting.cloudfront_domain}/index.html"]
}

locals {
  // Root and dashboard URLs for redirect
  index_url    = "https://${module.hosting.cloudfront_domain}/index.html"
  login_url    = format(
    "https://%s.auth.%s.amazoncognito.com/login?response_type=token&client_id=%s&redirect_uri=%s",
    module.auth.cognito_domain,
    data.aws_region.current.name,
    module.auth.spa_client_id,
    module.hosting.dashboard_url
  )
  logout_url   = format(
    "https://%s.auth.%s.amazoncognito.com/logout?client_id=%s&logout_uri=%s",
    module.auth.cognito_domain,
    data.aws_region.current.name,
    module.auth.spa_client_id,
    local.index_url
  )
}


// Fetch current AWS region for hosted UI URL
data "aws_region" "current" {}


// Deploy SPA index.html with dynamic login_url
resource "aws_s3_object" "index" {
  bucket       = module.hosting.bucket_name
  key          = "index.html"
  content      = templatefile(
    "${path.module}/web/index.html.tpl",
    { login_url = local.login_url }
  )
  content_type = "text/html"
  depends_on   = [module.auth, module.hosting]
}

// Upload dashboard page with authentication guard
resource "aws_s3_object" "dashboard" {
  bucket       = module.hosting.bucket_name
  key          = "dashboard.html"
  content      = templatefile(
    "${path.module}/web/dashboard.html.tpl",
    {
      login_url  = local.login_url,
      logout_url = local.logout_url
    }
  )
  content_type = "text/html"
  depends_on   = [aws_s3_object.index]
}

