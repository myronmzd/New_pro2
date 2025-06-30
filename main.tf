terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "./modules/S3"
}

module "lambda" {
  source = "./modules/lambda"
  s3_bucket = module.s3.bucket_name
}

module "stepfunctions" {
  source = "./modules/Stepfunctions"
  lambda_arn = module.lambda.thumbnail_lambda_arn
  s3_bucket  = module.s3.bucket_name
}

module "events" {
  source = "./modules/Events"
  s3_bucket = module.s3.bucket_name
  stepfunction_arn = module.stepfunctions.state_machine_arn
}