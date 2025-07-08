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

resource "archive_file" "fixture" {
  type        = "zip"
  source_file = "/workspaces/New_pro2/app.py"
  output_path = "modules/lambda/app.zip"
}

resource "aws_lambda_function" "function" {
  provider      = aws.mumbai
  function_name = var.lambda_function_name // Use a variable for function name
  role          = var.lambda_roles
  handler       = var.lambda_handler // Use a variable for handler
  runtime       = var.lambda_runtime // Use a variable for runtime
  filename      = "${path.module}/app.zip"

  environment {
    variables = {
      S3_BUCKET = var.s3_bucket // Use a variable for S3 bucket
      STEP_FUNCTION_ARN = var.stepfunction_arn // Use a variable for Step Function ARN
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


