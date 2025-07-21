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