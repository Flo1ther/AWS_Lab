variable "region" {
  default = "eu-central-1"
}

variable "image" {
  description = "Equivalent of ACI image"
  type        = string
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}