output "lambda_function_name" {
  value = aws_lambda_function.function1.function_name
}

output "function_invoke_arns" {
  value = aws_lambda_function.function1.arn
}