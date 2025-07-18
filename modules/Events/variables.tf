variable "s3_bucket" {
  type = string
}

variable "stepfunction_arn" {
  type = string
}
variable "aws_region" {
  description = "AWS region"
  type        = string
}