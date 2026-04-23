variable "region1" {
  description = "Primary AWS region (analog of East US)"
  type        = string
  default     = "eu-central-1"
}

variable "region2" {
  description = "Secondary AWS region (analog of West US)"
  type        = string
  default     = "eu-west-1"
}

variable "region1_az" {
  description = "Availability Zone for the primary region VM"
  type        = string
  default     = "eu-central-1a"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "admin_ip" {
  description = "CIDR allowed for administration"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vm_size" {
  description = "Instance size for az104-10-vm0"
  type        = string
  default     = "t3.micro"
}