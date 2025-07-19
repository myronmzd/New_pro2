output "raw_bucket_name" {
  value = aws_s3_bucket.raw.bucket
} 
output "dump_bucket_name" {
  value = aws_s3_bucket.dump_bucket.bucket
}