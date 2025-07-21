output "lambda_function_names" {
  value = aws_lambda_function.function.function_name
}

output "function_invoke_arns" {
  value = aws_lambda_function.function.arn
}