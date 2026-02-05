terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.25.0"
    }
  }
}

variable "redirect_to_root_path" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

module "lambda_redirect_for_single_page" {
  source         = "../lambda_edge_star"
  lambda_content = replace(file("${path.module}/lambdas/redirect_for_single_page.js"), "REPLACE_PATH_TO_ROOT", var.redirect_to_root_path)
  function_name  = var.lambda_function_name
}

output "qualified_arn" {
  value = module.lambda_redirect_for_single_page.qualified_arn
}
