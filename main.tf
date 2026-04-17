provider "aws" {
  region = "us-east-1"
}

# IAM role
resource "aws_iam_role" "helpdesk_role" {
  name = "helpdesk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Policy
resource "aws_iam_policy" "helpdesk_policy" {
  name = "helpdesk-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["ec2:RunInstances", "ec2:DescribeInstances"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["support:CreateCase"],
        Resource = "*"
      }
    ]
  })
}

# Attach
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.helpdesk_role.name
  policy_arn = aws_iam_policy.helpdesk_policy.arn
}