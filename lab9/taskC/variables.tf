variable "region" {
  default = "eu-central-1"
}

variable "image_identifier" {
  description = "Hello world image for App Runner"
  type        = string
  default     = "public.ecr.aws/aws-containers/hello-app-runner:latest"
}