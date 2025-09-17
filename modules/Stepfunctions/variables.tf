
variable "s3bucket_raw_arn" {
  type = string
}
variable "s3bucket_dump_arn" {
  type = string
}

variable "dump_bucket_n" {
  description = "Name of the dump S3 bucket"
  type        = string
  
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
variable "ecs_cluster" {
  description = "ARN of the ECS cluster"
  type        = string 
}

variable "video_splitter_arn" {
  description = "ARN of the ECS task definition for video splitter"
  type        = string
}

variable "image_processor_arn" {
  description = "ARN of the ECS task definition for image processor"
  type        = string
}

variable "fargatesubnet" {
  description = "List of subnet IDs for Fargate tasks"
  type        = list(string)
}
variable "fargatesecurity" {
  description = "List of security group IDs for Fargate tasks"
  type        = list(string)
}


variable "raw_path" {
  description = "Raw path URL in the input S3 bucket"
  type        = string
  
}
variable "processing_path" {
  description = "Processing path URL in the dump S3 bucket"
  type        = string
  
}
variable "results_path" {
  description = "Results path URL in the dump S3 bucket"
  type        = string
  
}