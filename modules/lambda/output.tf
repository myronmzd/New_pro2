output "lambda_function_name" {
  value = aws_lambda_function.function.function_name
}

output "function_invoke_arns" {
  value = aws_lambda_function.function.arn
}