
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
variable "LambdaFunction1Name" {
  description = "Name of the first Lambda function"
  type        = string
}

variable "function1_invoke_arns" {
  description = "ARN of the first Lambda function for invocation"
  type        = string
}