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

# --------------------
# VPC (Azure VNet)
# --------------------

resource "aws_vpc" "core" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "CoreServicesVPC"
  }
}

# --------------------
# Internet Gateway
# --------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.core.id

  tags = {
    Name = "Core-IGW"
  }
}

# --------------------
# Subnets
# --------------------

resource "aws_subnet" "shared" {
  vpc_id            = aws_vpc.core.id
  cidr_block        = "10.20.10.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "SharedServicesSubnet"
  }
}

resource "aws_subnet" "database" {
  vpc_id            = aws_vpc.core.id
  cidr_block        = "10.20.20.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "DatabaseSubnet"
  }
}

# --------------------
# Route Table
# --------------------

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.core.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "shared_assoc" {
  subnet_id      = aws_subnet.shared.id
  route_table_id = aws_route_table.public_rt.id
}

# --------------------
# Security Group (NSG)
# --------------------

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.core.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# --------------------
# Private DNS (Route 53)
# --------------------

resource "aws_route53_zone" "private_zone" {
  name = "internal.lab"
  vpc {
    vpc_id = aws_vpc.core.id
  }

  comment = "Private DNS zone (Azure Private DNS analog)"
}