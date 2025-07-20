variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
}
variable "funtion_names" {
  description = "Names of the Lambda functions"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
}


variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "s3_bucket_dump" {
  description = "S3 bucket name"
  type        = string
  default     = ""
}

variable "s3_bucket_raw" {
  description = "S3 bucket name"
  type        = string
  default     = ""
}

variable "stepfunction_arn" {
  description = "Step Function ARN"
  type        = string
  default     = ""
}

variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
  default     = {}
}