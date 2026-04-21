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
# VPC Core
# --------------------
resource "aws_vpc" "core" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "CoreVPC" }
}

resource "aws_subnet" "core_subnet" {
  vpc_id            = aws_vpc.core.id
  cidr_block        = "10.10.10.0/24"
  availability_zone = "eu-central-1a"
  tags = { Name = "CoreSubnet" }
}

# --------------------
# VPC Manufacturing
# --------------------
resource "aws_vpc" "manu" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "ManufacturingVPC" }
}

resource "aws_subnet" "manu_subnet" {
  vpc_id            = aws_vpc.manu.id
  cidr_block        = "10.20.10.0/24"
  availability_zone = "eu-central-1a"
  tags = { Name = "ManufacturingSubnet" }
}

# --------------------
# VPC Peering
# --------------------
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = aws_vpc.core.id
  peer_vpc_id   = aws_vpc.manu.id

  tags = {
    Name = "Core-Manu-Peering"
  }
}

# --------------------
# Routetables for Core VPC
# --------------------
resource "aws_route_table" "core_rt" {
  vpc_id = aws_vpc.core.id

  route {
    cidr_block                = aws_vpc.manu.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = { Name = "Core-RouteTable" }
}

resource "aws_route_table_association" "core_assoc" {
  subnet_id      = aws_subnet.core_subnet.id
  route_table_id = aws_route_table.core_rt.id
}

# --------------------
# Routetables for Manufacturing VPC
# --------------------
resource "aws_route_table" "manu_rt" {
  vpc_id = aws_vpc.manu.id

  route {
    cidr_block                = aws_vpc.core.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = { Name = "Manufacturing-RouteTable" }
}

resource "aws_route_table_association" "manu_assoc" {
  subnet_id      = aws_subnet.manu_subnet.id
  route_table_id = aws_route_table.manu_rt.id
}

# --------------------
# Security Groups
# --------------------
resource "aws_security_group" "core_sg" {
  name        = "core-sg"
  vpc_id      = aws_vpc.core.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.manu.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "manu_sg" {
  name        = "manu-sg"
  vpc_id      = aws_vpc.manu.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.core.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}