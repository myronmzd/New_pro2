output "raw_bucket_name" {
  value = aws_s3_bucket.Input_bucket.bucket
} 
output "dump_bucket_name" {
  value = aws_s3_bucket.dump_bucket.bucket
}
output "raw_bucket_arn" {
  value = aws_s3_bucket.Input_bucket.arn
}
output "dump_bucket_arn" {
  value = aws_s3_bucket.dump_bucket.arn
}


output "s3_input_raw_urls" {
  value = "s3://${aws_s3_bucket.Input_bucket.bucket}/raw/"
}

output "s3_dump_processing_urls" {
  value = "s3://${aws_s3_bucket.dump_bucket.bucket}/processing/"
}

output "s3_dump_results_urls" {
  value = "s3://${aws_s3_bucket.dump_bucket.bucket}/results/"
}