terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.25.0"
    }
  }
}

data "archive_file" "clean_url_rewrite" {
  type        = "zip"
  output_path = "${path.module}/.zip/clean_url_rewrite.zip"

  source {
    filename = "index.js"
    content  = file("${path.module}/lambdas/clean_url_rewrite.js")
  }
}

resource "aws_lambda_function" "clean_url_rewrite" {
  function_name    = "clean-url-rewrite"
  filename         = data.archive_file.clean_url_rewrite.output_path
  source_code_hash = data.archive_file.clean_url_rewrite.output_base64sha256
  role             = aws_iam_role.lambda_service_role.arn
  runtime          = "nodejs24.x"
  handler          = "index.handler"
  memory_size      = 128
  timeout          = 3
  publish          = true
}

data "aws_iam_policy_document" "lambda_execute_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "lambda_service_role" {
  name               = "cf-s3-static-web-lambda-role"
  path               = "/"
  description        = "Allows Lambda to execute"
  assume_role_policy = data.aws_iam_policy_document.lambda_execute_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_service_role_execution" {
  role       = aws_iam_role.lambda_service_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

output "qualified_arn" {
  value = aws_lambda_function.clean_url_rewrite.qualified_arn
}
