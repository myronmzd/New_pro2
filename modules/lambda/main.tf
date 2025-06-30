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

resource "aws_lambda_function" "thumbnail" {
  function_name = "Generate-Thumbnail"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "lambda_thumbnail.zip" # You must package and upload this
  environment {
    variables = {
      S3_BUCKET = var.s3_bucket
    }
  }
}

output "thumbnail_lambda_arn" {
  value = aws_lambda_function.thumbnail.arn
}

variable "s3_bucket" {
  type = string
}