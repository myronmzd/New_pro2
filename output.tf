output "s3_raw_bucket_name" {
  description = "Name of the raw S3 bucket"
  value       = module.s3.raw_bucket_name
}

output "s3_dump_bucket_name" {
  description = "Name of the dump S3 bucket"
  value       = module.s3.dump_bucket_name
}

output "stepfunction_arn" {
  description = "ARN of the Step Function state machine"
  value       = module.stepfunctions.state_machine_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = module.events_sns.aws_sns_topic_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}