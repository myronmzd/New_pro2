provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Application = "video-crash-detector"
    Owner       = "bob"
  }
}

resource "aws_iam_policy" "lambda_exec_policy" {
  name = "lambda_exec_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:HeadObject"
        ]
        Resource = [
          var.input_bucket_arn,
          "${var.input_bucket_arn}/*",
          var.output_bucket_arn,
          "${var.output_bucket_arn}/*"
        ]
      },
      {
        Sid    = "S3ListAllBuckets"
        Effect = "Allow"
        Action = ["s3:ListAllMyBuckets"]
        Resource = ["*"]
      },
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          var.sns_arn
        ]
      },
      {
        Sid    = "RekognitionAccess"
        Effect = "Allow"
        Action = [
          "rekognition:DetectCustomLabels"
        ]
        Resource = [
          var.rekognition_model_arn
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
  tags = local.common_tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
  
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags = local.common_tags
}

# Attach the policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}



resource "archive_file" "app1" {
  type        = "zip"
  source_file = "/workspaces/New_pro2/app1.go"
  output_path = "modules/lambda/app1.zip"
  output_file_mode = "0644"
}
resource "archive_file" "app2" {
  type        = "zip"
  source_file = "/workspaces/New_pro2/app2.go"
  output_path = "modules/lambda/app2.zip"
  output_file_mode = "0644"
}

resource "aws_lambda_function" "function1" {


  function_name = var.project_name
  handler       = var.lambda_handler // Use a variable for handler
  role          = aws_iam_role.lambda_exec.arn
  runtime       = var.lambda_runtime // Use a variable for runtime
  filename = "${path.module}/app1.zip"

  environment {
  variables = {
    S3_BUCKET_R     = var.s3_bucket_raw
    S3_BUCKET_D     = var.s3_bucket_dump
    STEP_FUNCTION_ARN = var.stepfunction_arn
    SNS_TOPIC_ARN   = var.sns_arn
    FRAME_RATE      = "1"
    MIN_CONFIDENCE  = "80"
  }
  }
  tags = merge(
  var.default_tags,
  local.common_tags,
  {
    Environment = var.environment
    Project     = var.project_name
  }
  )
}


resource "aws_lambda_function" "function2" {


  function_name = var.project_name  
  handler       = var.lambda_handler // Use a variable for handler
  role          = aws_iam_role.lambda_exec.arn
  runtime       = var.lambda_runtime // Use a variable for runtime
  filename = "${path.module}/app1.zip"

  environment {
  variables = {
    S3_BUCKET_D     = var.s3_bucket_dump
    STEP_FUNCTION_ARN = var.stepfunction_arn
    MODEL_ARN       = var.rekognition_model_arn
    SNS_TOPIC_ARN   = var.sns_arn
    FRAME_RATE      = "1"
    MIN_CONFIDENCE  = "80"
  }
  }
  tags = merge(
  var.default_tags,
  local.common_tags,
  {
    Environment = var.environment
    Project     = var.project_name
  }
  )
}
