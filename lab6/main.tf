terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# ---------- VPC ----------
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "lab6-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab_vpc.id
}

# ---------- Subnets ----------
data "aws_availability_zones" "azs" {}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------- Security Group ----------
resource "aws_security_group" "web_sg" {
  name   = "lab6-web-sg"
  vpc_id = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- EC2 ----------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "web1" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  user_data = <<EOF
#!/bin/bash
dnf install -y nginx
systemctl start nginx
echo "<h1>Web Server 1</h1>" > /usr/share/nginx/html/index.html
EOF

  tags = {
    Name = "web-1"
  }
}

resource "aws_instance" "web2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_2.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  user_data = <<EOF
#!/bin/bash
dnf install -y nginx
systemctl start nginx
echo "<h1>Web Server 2</h1>" > /usr/share/nginx/html/index.html
EOF

  tags = {
    Name = "web-2"
  }
}

# ---------- Load Balancer ----------
resource "aws_lb" "alb" {
  name               = "lab6-alb"
  load_balancer_type = "application"
  subnets            = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
  security_groups    = [aws_security_group.web_sg.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "lab6-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab_vpc.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "t1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "t2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web2.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}