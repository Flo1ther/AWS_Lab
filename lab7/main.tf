provider "aws" {
  region = var.region
}

resource "random_id" "rand" {
  byte_length = 4
}

# -------------------------
# S3 (Blob Storage)
# -------------------------
resource "aws_s3_bucket" "storage" {
  bucket        = "lab7-${random_id.rand.hex}"
  force_destroy = true

  tags = {
    Name = "Lab7 S3"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.storage.id

  rule {
    id     = "move-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
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
resource "aws_security_group" "efs_sg" {
  name_prefix = "efs-sg-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -------------------------
# EFS 
# -------------------------
resource "aws_efs_file_system" "efs" {
  creation_token = "efs-${random_id.rand.hex}"

  tags = {
    Name = "Lab7 EFS"
  }
}

# -------------------------
# Mount Target
# -------------------------
resource "aws_efs_mount_target" "mount" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = element(data.aws_subnets.default.ids, 0)
  security_groups = [aws_security_group.efs_sg.id]

  depends_on = [aws_efs_file_system.efs]
}