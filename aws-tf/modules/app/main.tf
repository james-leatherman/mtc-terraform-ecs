// Define local variables for ECR repository URL and authorization token
locals {
  ecr_url   = aws_ecr_repository.this.repository_url
  ecr_token = data.aws_ecr_authorization_token.this
}

// Fetch the ECR authorization token for Docker login
data "aws_ecr_authorization_token" "this" {}

// Create an ECR repository for storing Docker images
resource "aws_ecr_repository" "this" {
  name         = var.ecr_repository_name
  force_delete = true
}

// Log in to the ECR repository using Docker
resource "terraform_data" "login" {
  provisioner "local-exec" {
    command = <<EOT
        docker login ${local.ecr_url} \
        --username ${local.ecr_token.user_name} \
        --password ${local.ecr_token.password}
    EOT
  }
}

// Build the Docker image for the application
resource "terraform_data" "build" {
  triggers_replace = [var.image_version] // Rebuild the image if the version changes
  depends_on       = [terraform_data.login] // Ensure login happens before building
  provisioner "local-exec" {
    command = <<EOT
    docker build -t ${local.ecr_url} ${path.module}/apps/${var.app_path}
    EOT
  }
}

// Push the Docker image to the ECR repository
resource "terraform_data" "push" {
  triggers_replace = [var.image_version] // Push the image if the version changes
  depends_on       = [terraform_data.build] // Ensure the image is built before pushing
  provisioner "local-exec" {
    command = <<EOT
    docker image tag ${local.ecr_url} ${local.ecr_url}:${var.image_version}
    docker image tag ${local.ecr_url} ${local.ecr_url}:latest
    docker push ${local.ecr_url}:${var.image_version}
    docker push ${local.ecr_url}:latest
    EOT
  }
}

// Define the ECS task definition for the application
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.app_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  container_definitions = jsonencode([
    {
      name        = var.app_name
      image       = "${local.ecr_url}:${var.image_version}"
      cpu         = 256
      memory      = 512
      essential   = true
      environment = var.envars
      secrets     = var.secrets
      portMappings = [
        {
          containerPort = var.port
          hostPort      = var.port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "ecs/mtc-logs",
          "awslogs-region"        = "us-east-1",
          "awslogs-stream-prefix" = "mtc"
        }
      }
    }
  ])
}

// Define the ECS service to run the application
resource "aws_ecs_service" "this" {
  name            = "${var.app_name}-service"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.app_security_group_id]
    assign_public_ip = var.is_public
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.app_name
    container_port   = var.port
  }
}

// Define the ALB target group for the application
resource "aws_lb_target_group" "this" {
  name        = "${var.app_name}-tg"
  port        = var.port
  protocol    = "HTTP"
  target_type = "ip"
  health_check {
    enabled = true
    path    = var.healthcheck_path
  }
  vpc_id = var.vpc_id
}

// Define the ALB listener rule for routing traffic to the application
resource "aws_lb_listener_rule" "this" {
  listener_arn = var.alb_listener_arn
  priority     = var.lb_priority
  condition {
    path_pattern {
      values = [var.path_pattern]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}