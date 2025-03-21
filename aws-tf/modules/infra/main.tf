# Define local variables
locals {
  # Get the list of available availability zones
  azs = data.aws_availability_zones.available.names
}

# Create a CloudWatch log group for ECS logs
resource "aws_cloudwatch_log_group" "this" {
  name = "ecs/mtc-logs"
}

# Create a VPC with the specified CIDR block
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "mtc-ecs-vpc"
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "this" {
  tags = {
    Name = "mtc-ecs-igw"
  }
}

# Attach the Internet Gateway to the VPC
resource "aws_internet_gateway_attachment" "this" {
  internet_gateway_id = aws_internet_gateway.this.id
  vpc_id              = aws_vpc.this.id
}

# Create a route table for the VPC
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "mtc-ecs-rt"
  }
}

# Add a default route to the route table for internet access
resource "aws_route" "this" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Fetch the list of available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create public subnets in the VPC
resource "aws_subnet" "this" {
  for_each          = { for i in range(var.num_subnets) : "public${i}" => i }
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, each.value)
  availability_zone = local.azs[each.value % length(local.azs)]
  tags = {
    Name = "mtc-ecs-${each.key}"
  }
}

# Associate the subnets with the route table
resource "aws_route_table_association" "this" {
  for_each       = aws_subnet.this
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this.id
}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "this" {
  name               = "mtc-ecs-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [for az, id in { for s in aws_subnet.this : s.availability_zone => s.id... } : id[0]]
  tags = {
    Name = "mtc-ecs-lb"
  }
}

# Create a listener for the ALB
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action for the listener
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Work in progress"
      status_code  = "503"
    }
  }
}

# Create an ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "mtc-ecs-cluster"
}

# Create an IAM role for ECS task execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create an IAM policy to allow ECS tasks to read secrets
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "ecsSecretsPolicy"
  description = "Allow ECS tasks to read secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
      }
    ]
  })
}

# Attach the Amazon ECS Task Execution Role Policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  depends_on = [aws_iam_role.ecs_execution_role]
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach the custom secrets policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attachment" {
  depends_on = [aws_iam_role.ecs_execution_role, aws_iam_policy.ecs_secrets_policy]
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}