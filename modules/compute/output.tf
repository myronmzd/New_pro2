output "ecs_cluster_arn" {
  value = aws_ecs_cluster.crash_video_cluster.arn
}
output "fargate_video_splitter_arn" {
  value = aws_ecs_task_definition.video_splitter.arn
}

output "fargate_video_splitter_family" {
  value = aws_ecs_task_definition.video_splitter.family
}

output "fargate_Image_processor_arn" {
  value = aws_ecs_task_definition.image_processor.arn
}

output "fargate_Image_processor_family" {
  value = aws_ecs_task_definition.image_processor.family
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


# network configuration for Fargate tasks

output "subnets" {
  value = [data.aws_subnets.default.ids[0]]
}
output "security_groups" {
  value = [aws_security_group.fargate_sg.id]
}