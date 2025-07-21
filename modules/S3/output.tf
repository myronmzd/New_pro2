output "raw_bucket_name" {
  value = aws_s3_bucket.raw.bucket
} 
output "dump_bucket_name" {
  value = aws_s3_bucket.dump_bucket.bucket
}
output "raw_bucket_arn" {
  value = aws_s3_bucket.raw.arn
}
output "dump_bucket_arn" {
  value = aws_s3_bucket.dump_bucket.arn
}