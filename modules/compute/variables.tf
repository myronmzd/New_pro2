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
  type = map(string)
  description = "Default tags to apply to all compute resources"
}
variable "input_bucket_arn" {
  description = "ARN of the input video S3 bucket"
  type        = string
}

variable "output_bucket_arn" {
  description = "ARN of the output (dump) bucket for frames"
  type        = string
}

variable "ecr_repository_url1" {
  description = "ECR repository URL for the video processor image"
  type        = string
}
variable "ecr_repository_url2" {
  description = "ECR repository URL for the video processor image"
  type        = string
}