output "cdn_url" {
  value = aws_cloudfront_distribution.distribution.domain_name
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.distribution.hosted_zone_id
}

output "bucket_id" {
  value = aws_s3_bucket.website.id
}

output "bucket_arn" {
  value = aws_s3_bucket.website.arn
}
