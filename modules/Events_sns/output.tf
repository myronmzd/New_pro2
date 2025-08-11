output "aws_sns_topic_arn" {
  description = "The ARN of the SNS topic for file processing notifications"
  value       = aws_sns_topic.file_processing_topic.arn
}

output "sns_topic_name" {
  description = "The name of the SNS topic for file processing notifications"
  value       = aws_sns_topic.file_processing_topic.name
}