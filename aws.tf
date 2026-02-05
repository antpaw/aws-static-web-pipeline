variable "env" {
  type = string
}

variable "codecommit_user_ssh" {
  type = string
}

variable "unique_id" {
  type = string
}

# DOCKER
variable "dockerhub_username" {
  type = string
}
variable "dockerhub_password" {
  type = string
}

provider "aws" {
  region  = "eu-central-1"
  profile = "YOUR_AWS_PROFILE"
}

provider "aws" {
  alias   = "virginia"
  region  = "us-east-1"
  profile = "YOUR_AWS_PROFILE"
}

#####################
#####################
#####################
#####################
#####################
#####################
### STARS
#####################

module "codepipeline_star" {
  source    = "./modules/codepipeline_star"
  unique_id = var.unique_id
}

module "codebuild_star" {
  source                     = "./modules/codebuild_star"
  unique_id                  = var.unique_id
  codepipeline_artifacts_arn = module.codepipeline_star.artifacts_bucket_arn
}

# module "codedeploy_star" {
#   source = "./modules/codedeploy_star"
# }

module "codecommit_star" {
  source              = "./modules/codecommit_star"
  user_ssh_public_key = var.codecommit_user_ssh
}

output "default_git_ssh_user" {
  value = module.codecommit_star.git_ssh_user
}

#####################
#####################
#####################
#####################
#####################
#####################
### EXAMPLE
#####################

### ACM

data "aws_acm_certificate" "example_com" {
  domain   = "example.com"
  provider = aws.virginia
}

#####################
### HOSTING example.com
#####################

module "main_cf_s3_cache_policies" {
  source = "./modules/cf_s3_cache_policies"
}

module "main_website_cf_s3_static_web" {
  source                         = "./modules/cf_s3_static_web"
  bucket_id                      = "example-com-website-${var.env}"
  acm_certificate_arn            = data.aws_acm_certificate.example_com.arn
  aliases                        = ["www.example.com"]
  s3_web_hosting_cache_policy_id = module.main_cf_s3_cache_policies.s3_web_hosting_id
  s3_assets_cache_policy_id      = module.main_cf_s3_cache_policies.s3_assets_id
}

output "main_website_cdn_url" {
  value = module.main_website_cf_s3_static_web.cdn_url
}

module "main_website_cf_s3_domain_redirect" {
  source                   = "./modules/cf_s3_domain_redirect"
  bucket_id                = "example-com-website-redirect-${var.env}"
  redirect_all_requests_to = "www.example.com"
  acm_certificate_arn      = data.aws_acm_certificate.example_com.arn
  aliases                  = ["example.com"]
  cache_policy_id          = module.main_cf_s3_cache_policies.s3_web_redirect_id
}

output "main_website_redirect_cdn_url" {
  value = module.main_website_cf_s3_domain_redirect.cdn_url
}

#####################
### CI example.com
#####################
module "main_website_static_web_pipeline" {
  source = "./modules/static_web_pipeline"

  project_name = "main-website-${var.env}"

  website_s3_bucket_id          = module.main_website_cf_s3_static_web.bucket_id
  website_s3_bucket_arn         = module.main_website_cf_s3_static_web.bucket_arn
  codebuild_role_name           = module.codebuild_star.role_name
  codebuild_role_arn            = module.codebuild_star.role_arn
  codebuild_artifacts_bucket    = module.codebuild_star.artifacts_bucket
  codepipeline_role_arn         = module.codepipeline_star.role_arn
  codepipeline_artifacts_bucket = module.codepipeline_star.artifacts_bucket
  dockerhub_username            = var.dockerhub_username
  dockerhub_password            = var.dockerhub_password
}

output "main_website_git_clone_url_ssh" {
  value = module.main_website_static_web_pipeline.website_git_clone_url_ssh
}
