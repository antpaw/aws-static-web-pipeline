variable "project_name" {
  type = string
}

variable "codepipeline_arn" {
  type = string
}

variable "codecommit_repository_arn" {
  type = string
}


resource "aws_iam_role" "codepipeline_events" {
  name = "cwe-role-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_policy" "start_pipeline" {
  name = "start-pipeline-execution-${var.project_name}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
        Resource = [
          var.codepipeline_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "start_pipeline" {
  role       = aws_iam_role.codepipeline_events.name
  policy_arn = aws_iam_policy.start_pipeline.arn
}

resource "aws_cloudwatch_event_rule" "codecommit_to_codepipeline" {
  name        = "codepipeline-${var.project_name}"
  description = "Amazon CloudWatch Events rule to automatically start your pipeline when a change occurs in the AWS CodeCommit source repository and branch."

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = [var.codecommit_repository_arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = ["main"]
    }
  })
}

resource "aws_cloudwatch_event_target" "codecommit_to_codepipeline" {
  target_id = "codepipeline-target-${var.project_name}"
  rule      = aws_cloudwatch_event_rule.codecommit_to_codepipeline.name
  arn       = var.codepipeline_arn
  role_arn  = aws_iam_role.codepipeline_events.arn
}
