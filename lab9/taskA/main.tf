provider "aws" {
  region = var.region
}

locals {
  resource_group_name = "az104-rg9"
  web_app_name        = var.web_app_name
  staging_slot_name   = "staging"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# -------------------------
# Elastic Beanstalk App
# -------------------------
resource "aws_elastic_beanstalk_application" "web_app" {
  name        = local.web_app_name
  description = "AWS equivalent of Azure Web App"

  tags = {
    ResourceGroup = local.resource_group_name
  }
}

# -------------------------
# S3 for application versions
# -------------------------
resource "aws_s3_bucket" "app_versions" {
  bucket        = "${local.web_app_name}-appversions-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_object" "staging_bundle" {
  bucket = aws_s3_bucket.app_versions.id
  key    = "app.zip"
  source = var.application_package
  etag   = filemd5(var.application_package)
}

resource "aws_elastic_beanstalk_application_version" "staging_version" {
  name        = "staging-v1"
  application = aws_elastic_beanstalk_application.web_app.name
  bucket      = aws_s3_bucket.app_versions.id
  key         = aws_s3_object.staging_bundle.key
}

# -------------------------
# IAM roles for Elastic Beanstalk
# -------------------------
resource "aws_iam_role" "beanstalk_service_role" {
  name = "aws-elasticbeanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "beanstalk_service_health" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "beanstalk_service_updates" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

resource "aws_iam_role" "beanstalk_ec2_role" {
  name = "aws-elasticbeanstalk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_web" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_worker" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_docker" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_instance_profile" "beanstalk_ec2_profile" {
  name = "aws-elasticbeanstalk-ec2-role"
  role = aws_iam_role.beanstalk_ec2_role.name
}

# -------------------------
# Staging environment
# -------------------------
resource "aws_elastic_beanstalk_environment" "staging" {
  name          = "staging-v2"
  application   = aws_elastic_beanstalk_application.web_app.name
  platform_arn  = var.platform_arn
  version_label = aws_elastic_beanstalk_application_version.staging_version.name

  wait_for_ready_timeout = "20m"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_service_role.name
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "2"
  }

  tags = {
    ResourceGroup = local.resource_group_name
    Slot          = local.staging_slot_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.beanstalk_service_health,
    aws_iam_role_policy_attachment.beanstalk_service_updates,
    aws_iam_role_policy_attachment.beanstalk_ec2_web,
    aws_iam_role_policy_attachment.beanstalk_ec2_worker,
    aws_iam_role_policy_attachment.beanstalk_ec2_docker
  ]
}