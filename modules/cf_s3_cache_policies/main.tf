
resource "aws_cloudfront_cache_policy" "s3_web_redirect" {
  name        = "s3-web-redirect"
  min_ttl     = 120
  default_ttl = 120
  max_ttl     = 120
  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    cookies_config {
      cookie_behavior = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "s3_web_hosting" {
  name        = "s3-web-hosting"
  min_ttl     = 120
  default_ttl = 120
  max_ttl     = 120
  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    cookies_config {
      cookie_behavior = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "s3_assets" {
  name        = "s3-assets"
  min_ttl     = 31536000
  default_ttl = 31536000
  max_ttl     = 31536000
  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    cookies_config {
      cookie_behavior = "none"
    }
  }
}

output "s3_web_redirect_id" {
  value = aws_cloudfront_cache_policy.s3_web_redirect.id
}

output "s3_web_hosting_id" {
  value = aws_cloudfront_cache_policy.s3_web_hosting.id
}

output "s3_assets_id" {
  value = aws_cloudfront_cache_policy.s3_assets.id
}
