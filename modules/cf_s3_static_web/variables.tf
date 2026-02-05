variable "bucket_id" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "aliases" {
  type    = list(any)
  default = []
}

variable "cf_origin_id" {
  type    = string
  default = "S3OriginMainWebsite"
}
