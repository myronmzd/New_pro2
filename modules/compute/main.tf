provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Application = "video-crash-detector"
    Owner       = "bob"
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id] 
  }
}

# Security group for Fargate tasks
resource "aws_security_group" "fargate_sg" {
  name_prefix = "${var.project_name}-fargate-"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, local.common_tags)
}


# ECS Cluster
resource "aws_ecs_cluster" "crash_video_cluster" {
  name = "${var.project_name}-crash_video_cluster"
  tags = merge(var.default_tags, local.common_tags)
}

# Fargate execution role
resource "aws_iam_role" "fargate_execution_role" {
  name = "${var.project_name}-fargate-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Fargate task role
resource "aws_iam_role" "fargate_task_role" {
  name = "${var.project_name}-fargate-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Execution role policy
resource "aws_iam_role_policy_attachment" "fargate_execution_role_policy" {
  role       = aws_iam_role.fargate_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role policy
resource "aws_iam_role_policy" "fargate_task_policy" {
  name = "${var.project_name}-fargate-task-policy"
  role = aws_iam_role.fargate_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${var.input_bucket_arn}/*",
          "${var.output_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectCustomLabels"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "fargate_logs_1" {
  name              = "/ecs/${var.project_name}-video-processor"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "fargate_logs_2" {
  name              = "/ecs/${var.project_name}-Image-processor"
  retention_in_days = 7
}



# Fargate task definition
resource "aws_ecs_task_definition" "video_splitter" {
  family                   = "${var.project_name}-Image-processor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.fargate_execution_role.arn
  task_role_arn           = aws_iam_role.fargate_task_role.arn

  container_definitions = jsonencode([{
    name  = "video-processor"
    image = var.ecr_repository_url1
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.fargate_logs_1.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "video_splitter_ecs"
      }
    }
    
    essential = true
  }])
}

resource "aws_ecs_service" "video_splitter" {
  name            = "video-service-video-splitter"
  cluster         = aws_ecs_cluster.crash_video_cluster.id
  task_definition = aws_ecs_task_definition.video_splitter.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnets.default.ids[0]] # Use the first default subnet
    security_groups  = [aws_security_group.fargate_sg.id] 
    assign_public_ip = true   
    # farget does not need public IP but to talk to other pulling 
    # Docker images from Docker Hub, calling an external API
  }
}



resource "aws_ecs_task_definition" "image_processor" {
  family                   = "${var.project_name}-image-processor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.fargate_execution_role.arn
  task_role_arn           = aws_iam_role.fargate_task_role.arn

  container_definitions = jsonencode([{
    name  = "Image-processor"
    image = var.ecr_repository_url2

    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.fargate_logs_2.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "image_processor_ecs"
      }
    }
    
    essential = true
  }])
}


resource "aws_ecs_service" "image_processor" {
  name            = "video-service-image-processor"
  cluster         = aws_ecs_cluster.crash_video_cluster.id
  task_definition = aws_ecs_task_definition.image_processor.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnets.default.ids[0]] # Use the first default subnet
    security_groups  = [aws_security_group.fargate_sg.id] 
    assign_public_ip = true   
    # farget does not need public IP but to talk to other pulling 
    # Docker images from Docker Hub, calling an external API
  }
}