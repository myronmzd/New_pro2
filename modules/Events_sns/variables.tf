variable "s3_bucket" {
  type = string
}

variable "stepfunction_arn" {
  type = string
}
variable "aws_region" {
  description = "AWS region"
  type        = string
}
variable "email_endpoint" {
  description = "Email endpoint for SNS subscription"
  type        = string
}

variable "output_bucket_id"{
  description = "Output S3 bucket ID for Lambda environment variable"
  type        = string
}
variable "input_bucket_arn" {
  description = "ARN of the input S3 bucket"
  type        = string
}