provider "aws" {
  region = var.region
}

# -------------------------
# Default VPC
# -------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -------------------------
# Security Group
# -------------------------
resource "aws_security_group" "lab11_sg" {
  name_prefix = "lab11-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------
# EC2 Instance
# -------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "lab11_vm" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.lab11_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = "lab11-vm"
  }
}

# -------------------------
# SNS (аналог Action Group)
# -------------------------
resource "aws_sns_topic" "alerts" {
  name = "lab11-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# -------------------------
# CloudWatch Alarm (CPU)
# -------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "lab11-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  alarm_description = "CPU > 70%"

  dimensions = {
    InstanceId = aws_instance.lab11_vm.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}