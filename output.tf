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
