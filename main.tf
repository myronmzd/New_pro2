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
  lambda_handler = "app1.handler"
  lambda_runtime = "go1.x"
  environment    = "Production"
  funtion_names = "process-video"
  project_name   = "CarCrashApp"
  aws_region     = var.aws_region
  s3_bucket_raw     = module.s3.raw_bucket_name
  s3_bucket_dump    = module.s3.dump_bucket_name
  stepfunction_arn = module.stepfunctions.state_machine_arn
  input_bucket_arn = module.s3.raw_bucket_arn
  output_bucket_arn = module.s3.dump_bucket_arn
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


module "compute" {
  source = "./modules/compute"

  aws_region           = var.aws_region
  project_name         = "CarCrashApp"
  s3_bucket_raw        = module.s3.raw_bucket_name
  s3_bucket_dump       = module.s3.dump_bucket_name
  input_bucket_arn     = module.s3.raw_bucket_arn
  output_bucket_arn    = module.s3.dump_bucket_arn
  ecr_repository_url   = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app"
  
  default_tags = {
    Project     = "CarCrashApp"
    Environment = "Dev"
  }

  lambda_function_name = module.lambda.lambda_function_name
  function_invoke_arns = module.lambda.function_invoke_arns
}