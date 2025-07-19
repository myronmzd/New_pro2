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
  source = "./modules/lambda"
  lambda_handler = "app.handler"
  lambda_runtime = "python3.8"
  environment    = "Production"
  funtion_names = "process-video"
  project_name   = "CarCrashApp"
  aws_region     = var.aws_region
  s3_bucket_raw     = module.s3.raw_bucket_name
  s3_bucket_dump    = module.s3.dump_bucket_name
  stepfunction_arn = module.stepfunctions.state_machine_arn

}

module "stepfunctions" {
  source = "./modules/Stepfunctions"
  lambda = module.lambda.function_invoke_arns
  s3_bucket  = module.s3.raw_bucket_name
  aws_region = var.aws_region
}

module "events" {
  source = "./modules/Events"
  s3_bucket = module.s3.raw_bucket_name
  stepfunction_arn = module.stepfunctions.state_machine_arn
  aws_region          = var.aws_region
}