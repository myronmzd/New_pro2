locals {
  common_tags = {
    Application = "video-crash-detector"
    Owner       = "bob"
  }
}

provider "aws" {
  region = var.aws_region
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

# IAM Role for Step Functions
resource "aws_iam_role" "sfn_exec" {
  name               = "stepfunctions_exec_role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume_role.json
  tags               = local.common_tags
}

# Assume Role Policy
data "aws_iam_policy_document" "sfn_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

# IAM Policy for Step Functions
data "aws_iam_policy_document" "sfn_policy" {
  statement {
    sid     = "AllowLambdaInvoke"
    actions = ["lambda:InvokeFunction", "lambda:InvokeAsync"]
    resources = ["*"]
  }

  statement {
    sid     = "AllowRekognition"
    actions = ["rekognition:DetectCustomLabels"]
    resources = ["arn:aws:rekognition:ap-south-1:236024603923:project/Car_crash/version/Car_crash.2025-07-04T09.57.05/1751603227476"]
  }

  statement {
    sid     = "AllowCloudWatchLogDelivery"
    actions = [
        "logs:CreateLogDelivery",
        "logs:GetLogDelivery",
        "logs:UpdateLogDelivery",
        "logs:DeleteLogDelivery",
        "logs:ListLogDeliveries",
        "logs:PutResourcePolicy",
        "logs:DescribeResourcePolicies",
        "logs:DescribeLogGroups",
        "logs:GetResourcePolicy"
    ]
    resources = ["*"]
  }
  statement {
    sid     = "AllowCloudWatchLogging"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/stepfunctions/video-crash-detection:*"
  ]
}

  statement {
    sid     = "AllowS3Access"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
  var.s3bucket_raw_arn,
  "${var.s3bucket_raw_arn}/*",
  var.s3bucket_dump_arn,
  "${var.s3bucket_dump_arn}/*"
    ]
  }
}

# Attach Policy to Role
resource "aws_iam_role_policy" "sfn_policy" {
  name   = "stepfunctions_policy"
  role   = aws_iam_role.sfn_exec.id
  policy = data.aws_iam_policy_document.sfn_policy.json
}

# CloudWatch Logs for Step Functions
resource "aws_cloudwatch_log_group" "sfn_logs" {
  name              = "/aws/stepfunctions/video-crash-detection"
  retention_in_days = 7
  tags              = local.common_tags
}

# Step Function State Machine
resource "aws_sfn_state_machine" "video_crash_detection" {
  name     = "video-crash-detection"
  type     = "STANDARD"
  role_arn = aws_iam_role.sfn_exec.arn
  definition = local.state_machine_definition

  logging_configuration {
    include_execution_data = true
    level                  = "ALL"
    log_destination        = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.sfn_logs.name}:*"
  }
  tags = local.common_tags
  depends_on = [aws_iam_role_policy.sfn_policy]
}
