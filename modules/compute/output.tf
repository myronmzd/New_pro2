output "lambda_function_name" {
  value = aws_lambda_function.function.function_name
}

output "function_invoke_arns" {
  value = aws_lambda_function.function.arn
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.video_processing.arn
}

output "fargate_task_definition_arn" {
  value = aws_ecs_task_definition.video_processor.arn
}

output "fargate_task_role_arn" {
  value = aws_iam_role.fargate_task_role.arn
}