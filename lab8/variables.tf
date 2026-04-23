variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "admin_ip" {
  description = "CIDR allowed for RDP/administration"
  type        = string
  default     = "0.0.0.0/0"
}

variable "web_ingress_cidr" {
  description = "CIDR allowed to access ALB over HTTP"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vm_instance_type" {
  description = "Instance type for standalone EC2 VMs"
  type        = string
  default     = "t3.micro"
}

variable "asg_instance_type" {
  description = "Instance type for Auto Scaling Group"
  type        = string
  default     = "t3.micro"
}