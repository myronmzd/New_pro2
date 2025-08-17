variable "lambda" {
  type = string
}
variable "s3bucket_raw_arn" {
  type = string
}
variable "s3bucket_dump_arn" {
  type = string
}
variable "aws_region" {
  description = "AWS region"
  type        = string
}
variable "sns_stepfunctions" {
  description = "Name of the SNS topic"
  type        = string
}
variable "default_subnets" {
  description = "List of default subnet IDs"
  type        = list(string)
}

variable "lambda_function1_name" {
  description = "Name of the first Lambda function"
  type        = string
}

variable "function1_invoke_arns" {
  description = "ARN of the first Lambda function for invocation"
  type        = string
}

variable "lambda_function2_name" {
  description = "Name of the second Lambda function"
  type        = string
}

variable "function2_invoke_arns" {
  description = "ARN of the second Lambda function for invocation"
  type        = string
}