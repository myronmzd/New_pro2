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
  input_bucket_arn = module.s3.raw_bucket_arn
  output_bucket_arn = module.s3.dump_bucket_arn
  rekognition_model_arn = "arn:aws:rekognition:us-east-1:123456789012:project/CarCrashDetection/version/CarCrashDetection.2023-10-01T12.00.00/1700000000"
  sns_arn = module.events_sns.aws_sns_topic_arn
}

module "stepfunctions" {
  source = "./modules/Stepfunctions"
  lambda = module.lambda.function_invoke_arns
  s3bucket_raw_arn        = module.s3.raw_bucket_arn
  s3bucket_dump_arn       = module.s3.dump_bucket_arn
  aws_region = var.aws_region
}

module "events_sns" {
  source = "./modules/Events_sns"
  s3_bucket_raw        = module.s3.raw_bucket_name
  s3_bucket_dump       = module.s3.dump_bucket_name
  stepfunction_arn = module.stepfunctions.state_machine_arn
  aws_region          = var.aws_region
  email_endpoint      = "myronmzd22@gmail.com"
  output_bucket_id    = module.s3.dump_bucket_name
}