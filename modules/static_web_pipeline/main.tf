variable "project_name" {
  type = string
}

variable "image" {
  type    = string
  default = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
}

variable "build_timeout" {
  type    = string
  default = "5"
}

variable "website_s3_bucket_id" {
  type = string
}

variable "website_s3_bucket_arn" {
  type = string
}

variable "codebuild_role_name" {
  type = string
}

variable "codebuild_role_arn" {
  type = string
}

variable "codepipeline_role_arn" {
  type = string
}

variable "codepipeline_artifacts_bucket" {
  type = string
}

variable "codebuild_artifacts_bucket" {
  type = string
}

variable "app_stage" {
  type    = string
  default = "default"
}

variable "app_domain" {
  type    = string
  default = "missing"
}

variable "dockerhub_username" {
  type    = string
  default = "missing"
}

variable "dockerhub_password" {
  type    = string
  default = "missing"
}

variable "custom_environment_variables" {
  type    = map(any)
  default = {}
}

#####################
#####################
#####################
#####################
#####################
#####################
### CODECOMMIT
#####################
resource "aws_codecommit_repository" "website" {
  repository_name = var.project_name
  description     = "${var.project_name} Repository"
  default_branch  = "main"
}

output "website_git_clone_url_ssh" {
  value = aws_codecommit_repository.website.clone_url_ssh
}

#####################
#####################
#####################
#####################
#####################
#####################
### CODEBUILD
#####################

resource "aws_iam_policy" "codebuild_website_policy" {
  name        = "codebuild-${var.project_name}-policy"
  path        = "/service-role/"
  description = "Policy used to allow CodeBuild to use the website ${var.project_name} s3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [
          "${var.website_s3_bucket_arn}",
          "${var.website_s3_bucket_arn}/*"
        ]
        Action = [
          "s3:*"
        ]
      }
    ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = var.codebuild_role_name
  policy_arn = aws_iam_policy.codebuild_website_policy.arn
}

resource "aws_codebuild_project" "website" {
  name          = var.project_name
  description   = "${var.project_name} Task"
  build_timeout = var.build_timeout
  service_role  = var.codebuild_role_arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = "${var.codebuild_artifacts_bucket}/${var.project_name}-cache"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.image
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "S3_BUCKET_ID"
      value = var.website_s3_bucket_id
    }
    environment_variable {
      name  = "APP_STAGE"
      value = var.app_stage
    }
    environment_variable {
      name  = "APP_DOMAIN"
      value = var.app_domain
    }
    environment_variable {
      name  = "DOCKERHUB_USERNAME"
      value = var.dockerhub_username
    }
    environment_variable {
      name  = "DOCKERHUB_PASSWORD"
      value = var.dockerhub_password
    }

    dynamic "environment_variable" {
      for_each = var.custom_environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.website.clone_url_http
  }
}

#####################
#####################
#####################
#####################
#####################
#####################
### CODEPIPELINE
#####################

resource "aws_codepipeline" "website" {
  name     = var.project_name
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.codepipeline_artifacts_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.website.repository_name
        BranchName           = "main"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["website"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.website.name
      }
    }
  }
}

module "website_event_bridge" {
  source                    = "../git_pipeline_event_bridge"
  project_name              = var.project_name
  codepipeline_arn          = aws_codepipeline.website.arn
  codecommit_repository_arn = aws_codecommit_repository.website.arn
}

output "codepipeline_arn" {
  value = aws_codepipeline.website.arn
}

output "codebuild_project_name" {
  value = aws_codebuild_project.website.name
}
