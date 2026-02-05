variable "lambda_function_name" {
  type = string
}

module "lambda_error_pages" {
  source         = "../lambda_edge_star"
  lambda_content = file("${path.module}/lambdas/error_pages.js")
  function_name  = var.lambda_function_name
}

output "qualified_arn" {
  value = module.lambda_error_pages.qualified_arn
}
