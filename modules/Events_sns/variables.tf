variable "s3_bucket_raw" {
  type = string
}
variable "s3_bucket_dump" {
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
