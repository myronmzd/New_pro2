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
  aws_region = var.aws_region
}

module "lambda" {
  source               = "./modules/lambda"
  lambda_function_name = "Car-crash-app-function"
  lambda_handler       = "app.handler"
  lambda_runtime       = "python3.8"
  lambda_roles         = module.iam.lambda_role_arn
  dynamodb_table_name  = module.dynamodb.table_name
  environment          = "Production"
  project_name         = "CarCrashApp"
  aws_region          = var.aws_region
}

module "stepfunctions" {
  source = "./modules/Stepfunctions"
  lambda_arn = module.lambda.thumbnail_lambda_arn
  s3_bucket  = module.s3.bucket_name
  aws_region          = var.aws_region
}

module "events" {
  source = "./modules/Events"
  s3_bucket = module.s3.bucket_name
  stepfunction_arn = module.stepfunctions.state_machine_arn
  aws_region          = var.aws_region
}