output "lambda_function1_name" {
  value = aws_lambda_function.function1.function_name
}

output "function1_invoke_arns" {
  value = aws_lambda_function.function1.arn
}
