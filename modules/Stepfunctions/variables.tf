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
variable "fargate_task_arn" {
  description = "ARN of the Fargate task definition"
  type        = string
}
variable "fargete_role_arn" {
  description = "ARN of the Fargate task role"
  type        = string
}
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}
variable "task_definition_family" {
  description = "Family name of the task definition"
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
variable "fargate_security_group_id" {
  description = "Security group ID for Fargate tasks"
  type        = string
}
variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}