variable "region" {
  default = "eu-central-1"
}

variable "web_app_name" {
  description = "Equivalent of Azure Web App name"
  type        = string
}

variable "application_package" {
  description = "Path to ZIP file"
  type        = string
}

variable "platform_arn" {
  description = "Elastic Beanstalk platform ARN (PHP 8.2)"
  type        = string
}