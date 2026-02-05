# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform/OpenTofu modules for deploying static websites on AWS with CI/CD pipelines. Creates a complete hosting stack: S3 bucket → CloudFront CDN → Route53 DNS, with automated deployments via CodeCommit → CodePipeline → CodeBuild.

## Commands

```bash
# Terraform (or replace with `tofu` for OpenTofu)
terraform init                    # Initialize providers and modules
terraform plan                    # Preview changes
terraform apply                   # Apply infrastructure changes
terraform fmt -recursive          # Format all .tf files
terraform validate                # Validate configuration syntax
```

## Architecture

**Star modules** (shared infrastructure, instantiated once):
- `codepipeline_star` - Shared CodePipeline IAM role and artifacts S3 bucket
- `codebuild_star` - Shared CodeBuild IAM role and cache S3 bucket
- `codecommit_star` - IAM user for SSH git access to CodeCommit repos

**Per-website modules** (instantiated for each site):
- `static_web_pipeline` - Creates CodeCommit repo + CodeBuild project + CodePipeline, wires them together with EventBridge trigger on main branch push
- `cf_s3_static_web` - S3 bucket + CloudFront distribution with Origin Access Control (OAC), HTTPS via ACM certificate
- `cf_s3_domain_redirect` - S3 website redirect bucket + CloudFront for apex-to-www redirects
- `cf_s3_cache_policies` - Reusable CloudFront cache policies (2min for HTML, 1yr for assets)
- `git_pipeline_event_bridge` - EventBridge rule triggering pipeline on CodeCommit push

**Flow:** Push to CodeCommit main → EventBridge triggers CodePipeline → CodeBuild runs buildspec.yml → deploys to S3 website bucket → served via CloudFront

## Adding a New Website

1. Create ACM certificate in us-east-1 (required for CloudFront)
2. Instantiate `cf_s3_cache_policies` (once per account)
3. Instantiate `cf_s3_static_web` with certificate ARN and domain aliases
4. Instantiate `cf_s3_domain_redirect` for apex redirect (optional)
5. Instantiate `static_web_pipeline` referencing the website bucket
6. Create Route53 records pointing to CloudFront distributions

See `aws.tf` lines 74-136 for a complete example.

## Configuration

- Provider uses `eu-central-1` with `us-east-1` alias for ACM certificates
- Variables defined in `env-prod.auto.tfvars`: env, unique_id, codecommit_user_ssh, dockerhub credentials
- `unique_id` must be unique to avoid S3 bucket naming collisions
