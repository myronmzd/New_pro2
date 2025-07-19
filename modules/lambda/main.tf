provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
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

resource "archive_file" "app1" {
  type        = "zip"
  source_file = "/workspaces/New_pro2/app1.py"
  output_path = "modules/lambda/app1.zip"
}

# resource "archive_file" "app2" {
#   type        = "zip"
#   source_file = "/workspaces/New_pro2/app2.py"
#   output_path = "modules/lambda/app2.zip"
# }

# resource "archive_file" "app3" {
#   type        = "zip"
#   source_file = "/workspaces/New_pro2/app3.py"
#   output_path = "modules/lambda/app3.zip"
# }

resource "aws_lambda_function" "funtion" {


  function_name = var.project_name
  handler       = var.lambda_handler // Use a variable for handler
  role          = aws_iam_role.lambda_exec.arn
  runtime       = var.lambda_runtime // Use a variable for runtime
  filename = "${path.module}/app1.zip"

  environment {
    variables = {
      S3_BUCKET_R = var.s3_bucket_raw
      S3_BUCKET_D = var.s3_bucket_dump
      STEP_FUNCTION_ARN = var.stepfunction_arn 
    }
  }

  tags = merge(
    var.default_tags, // Use default tags from a variable
    {
      Environment = var.environment
      Project     = var.project_name
    }
  )
}
