variable "lambda_split" {
  type = string
}
variable "lambda_thumbnail" {
  type = string
}
variable "lambda_cleanup" {
  type = string
}
variable "s3_bucket" {
  type = string
}
variable "aws_region" {
  description = "AWS region"
  type        = string
}