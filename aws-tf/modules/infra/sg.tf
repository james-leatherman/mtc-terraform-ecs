# Security Group for ALB

resource "aws_security_group" "alb-sg" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "mtc-ecs-sg"
  }
}

# Allow HTTP inbound traffic from the internet to the ALB

resource "aws_vpc_security_group_ingress_rule" "alb-ir" {
  for_each          = var.allowed_ips
  security_group_id = aws_security_group.alb-sg.id
  cidr_ipv4         = each.value
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Allow All outbound traffic from the ALB to the app

resource "aws_vpc_security_group_egress_rule" "alb-er" {
  security_group_id            = aws_security_group.alb-sg.id
  referenced_security_group_id = aws_security_group.app-sg.id
  ip_protocol                  = "-1"
  tags = {
    Name = "allow-all-to-app"
  }
}

# Security Group for the app

resource "aws_security_group" "app-sg" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "mtc-ecs-app-sg"
  }
}

# Allow HTTP inbound traffic from the ALB to the app

resource "aws_vpc_security_group_ingress_rule" "app-ir" {
  security_group_id            = aws_security_group.app-sg.id
  referenced_security_group_id = aws_security_group.alb-sg.id
  ip_protocol                  = "-1"
  tags = {
    Name = "allow-http-from-alb"
  }
}

# Allow All outbound traffic from the app to the internet

resource "aws_vpc_security_group_egress_rule" "app-er" {
  security_group_id = aws_security_group.app-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  tags = {
    Name = "allow-all-to-internet"
  }
}