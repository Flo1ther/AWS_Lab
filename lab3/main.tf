terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# ---------------------------
# Random suffix
# ---------------------------
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ---------------------------
# AWS Account ID
# ---------------------------
data "aws_caller_identity" "current" {}

# ---------------------------
# AMI (динамічний)
# ---------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ---------------------------
# S3 Bucket (унікальний)
# ---------------------------
resource "aws_s3_bucket" "storage" {
  bucket = "my-terraform-lab-${data.aws_caller_identity.current.account_id}-${random_string.suffix.result}"

  tags = {
    Name        = "lab-storage"
    Environment = "dev"
  }
}

# ---------------------------
# Security Group (унікальний)
# ---------------------------
resource "aws_security_group" "web_sg" {
  name = "web-sg-${random_string.suffix.result}"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# EC2 Instance
# ---------------------------
resource "aws_instance" "vm" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "lab-vm"
  }
}