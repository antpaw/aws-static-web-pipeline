# AWS Static Web Pipeline

Terraform/OpenTofu modules for deploying static websites on AWS with automated CI/CD pipelines.

## Features

- **S3 + CloudFront hosting** with Origin Access Control (OAC)
- **Automated deployments** via CodeCommit → CodePipeline → CodeBuild
- **HTTPS** via ACM certificates
- **Apex domain redirects** (example.com → www.example.com)
- **Optimized caching** (2 min for HTML, 1 year for assets)
- **EventBridge triggers** for push-to-deploy on main branch

## Architecture

```
CodeCommit (git push)
    ↓
EventBridge (trigger)
    ↓
CodePipeline
    ↓
CodeBuild (runs buildspec.yml)
    ↓
S3 Bucket (website files)
    ↓
CloudFront CDN
    ↓
Route53 DNS
```

## Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.10.6 or [OpenTofu](https://opentofu.org/) >= 1.6.0
- AWS CLI configured with appropriate credentials
- ACM certificate in us-east-1 for your domain
- SSH public key for CodeCommit access

## Quick Start

1. Clone this repository

2. Update `aws.tf` with your AWS profile:
   ```hcl
   provider "aws" {
     region  = "eu-central-1"
     profile = "your-profile"
   }
   ```

3. Configure `env-prod.auto.tfvars`:
   ```hcl
   env = "prod"
   codecommit_user_ssh = "ssh-rsa YOUR_PUBLIC_KEY"
   unique_id = "123456"  # Unique identifier for S3 bucket names
   dockerhub_username = "your-username"
   dockerhub_password = "your-password"
   ```

4. Deploy:
   ```bash
   # Using Terraform
   terraform init
   terraform plan
   terraform apply

   # Or using OpenTofu
   tofu init
   tofu plan
   tofu apply
   ```

5. Configure git remote using the output SSH URL:
   ```bash
   git remote add aws ssh://YOUR_SSH_KEY_ID@git-codecommit.eu-central-1.amazonaws.com/v1/repos/main-website-prod
   git push aws main
   ```

## Module Reference

### Shared Infrastructure (Star Modules)

These modules create shared resources used by all pipelines:

| Module | Purpose |
|--------|---------|
| `codepipeline_star` | Shared IAM role and artifacts bucket for CodePipeline |
| `codebuild_star` | Shared IAM role and cache bucket for CodeBuild |
| `codecommit_star` | IAM user with SSH access for git operations |

### Per-Website Modules

| Module | Purpose |
|--------|---------|
| `static_web_pipeline` | CodeCommit repo + CodeBuild + CodePipeline + EventBridge trigger |
| `cf_s3_static_web` | S3 bucket + CloudFront with OAC |
| `cf_s3_domain_redirect` | Apex to www redirect via S3 + CloudFront |
| `cf_s3_cache_policies` | CloudFront cache policies |
| `git_pipeline_event_bridge` | EventBridge rule for CodeCommit → CodePipeline |

## Adding a Website

```hcl
# 1. Reference your ACM certificate (must be in us-east-1)
data "aws_acm_certificate" "example_com" {
  domain   = "example.com"
  provider = aws.virginia
}

# 2. Create cache policies (once per account)
module "cache_policies" {
  source = "./modules/cf_s3_cache_policies"
}

# 3. Create website hosting
module "website" {
  source                         = "./modules/cf_s3_static_web"
  bucket_id                      = "example-com-website-${var.env}"
  acm_certificate_arn            = data.aws_acm_certificate.example_com.arn
  aliases                        = ["www.example.com"]
  s3_web_hosting_cache_policy_id = module.cache_policies.s3_web_hosting_id
  s3_assets_cache_policy_id      = module.cache_policies.s3_assets_id
}

# 4. Create apex redirect (optional)
module "website_redirect" {
  source                   = "./modules/cf_s3_domain_redirect"
  bucket_id                = "example-com-redirect-${var.env}"
  redirect_all_requests_to = "www.example.com"
  acm_certificate_arn      = data.aws_acm_certificate.example_com.arn
  aliases                  = ["example.com"]
  cache_policy_id          = module.cache_policies.s3_web_redirect_id
}

# 5. Create CI/CD pipeline
module "website_pipeline" {
  source                        = "./modules/static_web_pipeline"
  project_name                  = "my-website-${var.env}"
  website_s3_bucket_id          = module.website.bucket_id
  website_s3_bucket_arn         = module.website.bucket_arn
  codebuild_role_name           = module.codebuild_star.role_name
  codebuild_role_arn            = module.codebuild_star.role_arn
  codebuild_artifacts_bucket    = module.codebuild_star.artifacts_bucket
  codepipeline_role_arn         = module.codepipeline_star.role_arn
  codepipeline_artifacts_bucket = module.codepipeline_star.artifacts_bucket
  dockerhub_username            = var.dockerhub_username
  dockerhub_password            = var.dockerhub_password
}

# 6. Create Route53 records
resource "aws_route53_record" "www" {
  name    = "www.example.com"
  type    = "A"
  zone_id = aws_route53_zone.example_com.zone_id
  alias {
    name                   = module.website.cdn_url
    zone_id                = module.website.hosted_zone_id
    evaluate_target_health = false
  }
}
```

## Build Configuration

Your website repository needs a `buildspec.yml` in the root. Example:

```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 18
  build:
    commands:
      - npm ci
      - npm run build
  post_build:
    commands:
      - aws s3 sync ./dist s3://$S3_BUCKET_ID --delete
```

Environment variables available in CodeBuild:
- `S3_BUCKET_ID` - Target S3 bucket
- `APP_STAGE` - Deployment stage
- `APP_DOMAIN` - Application domain

## License

MIT
