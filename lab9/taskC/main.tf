provider "aws" {
  region = var.region
}

locals {
  resource_group_name = "az104-rg9"
  container_app_name  = "my-app"
  environment_name    = "my-environment"
}

resource "aws_apprunner_auto_scaling_configuration_version" "my_environment" {
  auto_scaling_configuration_name = local.environment_name

  max_concurrency = 100
  min_size        = 1
  max_size        = 2

  tags = {
    ResourceGroup = local.resource_group_name
  }
}

resource "aws_apprunner_service" "my_app" {
  service_name = local.container_app_name

  source_configuration {
    auto_deployments_enabled = false

    image_repository {
      image_identifier      = var.image_identifier
      image_repository_type = "ECR_PUBLIC"

      image_configuration {
        port = "80"
      }
    }
  }

  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.my_environment.arn

  tags = {
    ResourceGroup = local.resource_group_name
    Environment   = local.environment_name
  }
}