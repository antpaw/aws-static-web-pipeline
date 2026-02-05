# S3
variable "unique_id" {
  type = string
}

variable "codestar_connections" {
  type    = list(string)
  default = []
}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "codepipeline-artifacts-1-${var.unique_id}"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

output "artifacts_bucket" {
  value = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "artifacts_bucket_arn" {
  value = aws_s3_bucket.codepipeline_artifacts.arn
}

output "artifacts_bucket_region" {
  value = aws_s3_bucket.codepipeline_artifacts.region
}

##########################
##########################
##########################
##########################
### CODEPIPELINE IAM ROLE
##########################

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

output "role_arn" {
  value = aws_iam_role.codepipeline_role.arn
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow",
        Resource = [
          "*"
        ],
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutRetentionPolicy",
          "logs:PutLogEvents"
        ]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::codepipeline*",
          "arn:aws:s3:::elasticbeanstalk*"
        ],
        Effect = "Allow"
      },
      {
        Action = [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "elasticbeanstalk:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "s3:*",
          "sns:*",
          "cloudformation:*",
          "rds:*",
          "sqs:*",
          "ecs:*",
          "iam:PassRole"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "opsworks:CreateDeployment",
          "opsworks:DescribeApps",
          "opsworks:DescribeCommands",
          "opsworks:DescribeDeployments",
          "opsworks:DescribeInstances",
          "opsworks:DescribeStacks",
          "opsworks:UpdateApp",
          "opsworks:UpdateStack"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate",
          "iam:PassRole"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Resource = "*",
        Effect   = "Allow"
      },
      # {
      #   Action   = "codestar-connections:UseConnection",
      #   Effect   = "Allow",
      #   Resource = var.codestar_connections
      # }
    ],
    Version = "2012-10-17"
  })

}
