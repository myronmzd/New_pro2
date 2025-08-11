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