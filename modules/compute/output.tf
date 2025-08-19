output "ecs_cluster_arn" {
  value = aws_ecs_cluster.video_processing.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.video_processing.name
}

output "fargate_task_definition_arn" {
  value = aws_ecs_task_definition.video_processor.arn
}

output "fargate_task_definition_family" {
  value = aws_ecs_task_definition.video_processor.family
}

output "fargate_task_role_arn" {
  value = aws_iam_role.fargate_task_role.arn
}

output "default_subnets" {
  value = data.aws_subnets.default.ids
}

output "fargate_security_group_id" {
  value = aws_security_group.fargate_sg.id
}