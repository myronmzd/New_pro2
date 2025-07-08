variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_roles" {
  description = "IAM role ARN for the Lambda function"
  type        = string
}

variable "lambda_handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "app.handler"
}

variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.8"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., Production, Staging)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}