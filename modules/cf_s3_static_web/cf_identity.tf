resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-${var.bucket_id}"
  description                       = "Origin Access Control for ${var.bucket_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "s3_cloudfront_oac_policy" {
  statement {
    sid     = "AllowCloudFrontServicePrincipal"
    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.website.arn}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}
