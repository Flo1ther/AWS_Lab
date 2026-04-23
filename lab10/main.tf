provider "aws" {
  region = var.region1
}

provider "aws" {
  alias  = "region2"
  region = var.region2
}

resource "random_id" "suffix" {
  byte_length = 4
}

# -------------------------
# Use default VPC and subnets
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
# Security group for az104-10-vm0
# -------------------------
resource "aws_security_group" "az104_10_vm0" {
  name_prefix = "az104-10-vm0-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  ingress {
    description = "SSH"
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

  tags = {
    Name          = "az104-10-vm0-sg"
    ResourceGroup = "az104-rg-region1"
  }
}

# -------------------------
# EC2 instance (analog of az104-10-vm0)
# -------------------------
data "aws_ami" "az104_10_vm0" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

resource "aws_instance" "az104_10_vm0" {
  ami                         = data.aws_ami.az104_10_vm0.id
  instance_type               = var.vm_size
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.az104_10_vm0.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name          = "az104-10-vm0"
    ResourceGroup = "az104-rg-region1"
  }
}

# -------------------------
# AWS Backup vaults
# -------------------------
resource "aws_backup_vault" "az104_rsv_region1" {
  name = "az104-rsv-region1"

  tags = {
    ResourceGroup = "az104-rg-region1"
  }
}

resource "aws_backup_vault" "az104_rsv_region2" {
  provider = aws.region2
  name     = "az104-rsv-region2"

  tags = {
    ResourceGroup = "az104-rg-region2"
  }
}

# -------------------------
# IAM role for AWS Backup
# -------------------------
resource "aws_iam_role" "az104_backup_role" {
  name = "az104-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "az104_backup_role_backup" {
  role       = aws_iam_role.az104_backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "az104_backup_role_restore" {
  role       = aws_iam_role.az104_backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# -------------------------
# Backup plan (analog of az104-backup)
# -------------------------
resource "aws_backup_plan" "az104_backup" {
  name = "az104-backup"

  rule {
    rule_name         = "az104-backup-daily"
    target_vault_name = aws_backup_vault.az104_rsv_region1.name
    schedule          = "cron(0 0 * * ? *)"

    lifecycle {
      delete_after = 30
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.az104_rsv_region2.arn

      lifecycle {
        delete_after = 30
      }
    }
  }

  tags = {
    ResourceGroup = "az104-rg-region1"
  }
}

resource "aws_backup_selection" "az104_10_vm0" {
  iam_role_arn = aws_iam_role.az104_backup_role.arn
  name         = "az104-10-vm0-selection"
  plan_id      = aws_backup_plan.az104_backup.id

  resources = [
    aws_instance.az104_10_vm0.arn
  ]
}