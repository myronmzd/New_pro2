provider "aws" {
  region = "ap-south-1"

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


locals {
  state_machine_definition = templatefile(
    "${path.module}/state_machine.json",
    {
      Region    = data.aws_region.current.name
      AccountId = data.aws_caller_identity.current.account_id
    }
  )
}


resource "aws_iam_role" "sfn_exec" {
  name = "stepfunctions_exec_role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume_role.json
}

data "aws_iam_policy_document" "sfn_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "sfn_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "rekognition:DetectCustomLabels"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sfn_policy" {
  name   = "stepfunctions_policy"
  role   = aws_iam_role.sfn_exec.id
  policy = data.aws_iam_policy_document.sfn_policy.json
}

resource "aws_cloudwatch_log_group" "sfn_logs" {
  name              = "/aws/stepfunctions/video-crash-detection"
  retention_in_days = 7
}

resource "aws_sfn_state_machine" "video_crash_detection" {
  name       = "video-crash-detection"
  type       = "STANDARD"
  role_arn   = aws_iam_role.sfn_exec.arn
  definition = local.state_machine_definition

  logging_configuration {
    include_execution_data = true
    level                 = "ALL"
    log_destination       = aws_cloudwatch_log_group.sfn_logs.arn
  }
}
