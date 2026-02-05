terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.25.0"
    }
  }
}

module "lambda_redirect_from_s3_header" {
  source         = "../lambda_edge_star"
  lambda_content = file("${path.module}/lambdas/redirect_from_s3_header.js")
  function_name  = "redirect-from-s3-header"
}

output "qualified_arn" {
  value = module.lambda_redirect_from_s3_header.qualified_arn
}
