terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "eu-central-1" # Frankfurt
}

# --------------------
# IAM USERS
# --------------------

resource "aws_iam_user" "user1" {
  name = "az104-user1"
}

resource "aws_iam_user" "user2" {
  name = "az104-user2"
}

# --------------------
# IAM GROUP
# --------------------

resource "aws_iam_group" "it_admins" {
  name = "IT-Lab-Administrators"
}

# --------------------
# GROUP MEMBERSHIP
# --------------------

resource "aws_iam_group_membership" "admins_membership" {
  name = "it-admins-membership"

  users = [
    aws_iam_user.user1.name,
    aws_iam_user.user2.name
  ]

  group = aws_iam_group.it_admins.name
}

# --------------------
# POLICY 
# --------------------

resource "aws_iam_policy" "lab_policy" {
  name        = "ITLabReadOnly"
  description = "Read-only access for lab administrators"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:Describe*",
          "s3:List*",
          "iam:Get*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "attach_policy" {
  group      = aws_iam_group.it_admins.name
  policy_arn = aws_iam_policy.lab_policy.arn
}