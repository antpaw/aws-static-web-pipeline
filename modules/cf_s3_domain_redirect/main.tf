variable "bucket_id" {
  type = string
}

variable "redirect_all_requests_to" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "cache_policy_id" {
  type = string
}

variable "aliases" {
  type    = list(string)
  default = []
}

variable "redirect_cf_origin_id" {
  type    = string
  default = "S3OriginMainWebsiteRedirect"
}

resource "aws_s3_bucket" "redirect" {
  bucket = var.bucket_id
}

resource "aws_s3_bucket_public_access_block" "redirect" {
  bucket = aws_s3_bucket.redirect.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "redirect" {
  bucket = aws_s3_bucket.redirect.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  bucket = aws_s3_bucket.redirect.id
  redirect_all_requests_to {
    host_name = var.redirect_all_requests_to
    protocol  = "https"
  }
}

resource "aws_cloudfront_distribution" "redirect_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.redirect.id}.${aws_s3_bucket_website_configuration.redirect.website_domain}"
    origin_id   = var.redirect_cf_origin_id

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""
  price_class         = "PriceClass_100"

  aliases = var.aliases

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = var.redirect_cf_origin_id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = var.cache_policy_id
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

output "cdn_url" {
  value = aws_cloudfront_distribution.redirect_distribution.domain_name
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.redirect_distribution.hosted_zone_id
}
