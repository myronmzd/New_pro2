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

variable "input_bucket_arn" {
  description = "ARN of the input video S3 bucket"
  type        = string
}

variable "output_bucket_arn" {
  description = "ARN of the output (dump) bucket for frames"
  type        = string
}

variable "rekognition_model_arn" {
  description = "ARN of the Rekognition Custom Label model"
  type        = string
}
variable "sns_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for Fargate tasks"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for Fargate tasks"
  type        = list(string)
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the video processor image"
  type        = string
  default     = "your-account.dkr.ecr.us-east-1.amazonaws.com/video-processor:latest"
}