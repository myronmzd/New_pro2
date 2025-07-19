output "lambda_function_names" {
  value = { for k, v in aws_lambda_function.funtions : k => v.function_name }
}

output "function_invoke_arns" {
  value = { for k, v in aws_lambda_function.funtions : k => v.invoke_arn }
}