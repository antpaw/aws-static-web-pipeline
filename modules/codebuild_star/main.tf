variable "unique_id" {
  type = string
}

variable "codepipeline_artifacts_arn" {
  type = string
}

# S3
resource "aws_s3_bucket" "codebuild_artifacts" {
  bucket = "codebuild-artifacts-1-${var.unique_id}"
}

resource "aws_s3_bucket_public_access_block" "codebuild_artifacts" {
  bucket = aws_s3_bucket.codebuild_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "codebuild_artifacts" {
  bucket = aws_s3_bucket.codebuild_artifacts.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

output "artifacts_bucket" {
  value = aws_s3_bucket.codebuild_artifacts.bucket
}

output "artifacts_bucket_arn" {
  value = aws_s3_bucket.codebuild_artifacts.arn
}

output "artifacts_bucket_region" {
  value = aws_s3_bucket.codebuild_artifacts.region
}

##########################
##########################
##########################
##########################
### CODEBUILD IAM ROLE
##########################

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

output "role_arn" {
  value = aws_iam_role.codebuild_role.arn
}

output "role_name" {
  value = aws_iam_role.codebuild_role.name
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [
          "*"
        ]
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.codebuild_artifacts.arn}",
          "${aws_s3_bucket.codebuild_artifacts.arn}/*",
          "${var.codepipeline_artifacts_arn}",
          "${var.codepipeline_artifacts_arn}/*"
        ]
        Action = [
          "s3:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}
