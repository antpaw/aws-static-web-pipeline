resource "aws_route53_zone" "example_com" {
  name          = "example.com."
  force_destroy = true
}

# terraform import aws_route53_zone.example_com Z3D30NNIGPLVRZ

resource "aws_route53_record" "example_com_A" {
  allow_overwrite = false
  name            = "example.com"
  type            = "A"
  zone_id         = aws_route53_zone.example_com.zone_id

  alias {
    name                   = "${module.main_website_cf_s3_domain_redirect.cdn_url}."
    zone_id                = module.main_website_cf_s3_domain_redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_example_com_A" {
  allow_overwrite = false
  name            = "www.example.com"
  type            = "A"
  zone_id         = aws_route53_zone.example_com.zone_id
  alias {
    name                   = "${module.main_website_cf_s3_static_web.cdn_url}."
    zone_id                = module.main_website_cf_s3_static_web.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_example_com_AAAA" {
  allow_overwrite = false
  name            = "www.example.com"
  type            = "AAAA"
  zone_id         = aws_route53_zone.example_com.zone_id
  alias {
    name                   = "${module.main_website_cf_s3_static_web.cdn_url}."
    zone_id                = module.main_website_cf_s3_static_web.hosted_zone_id
    evaluate_target_health = false
  }
}
