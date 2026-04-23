variable "region" {
  default = "eu-central-1"
}

variable "admin_ip" {
  description = "Your IP for SSH"
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "EC2 Key Pair name"
}

variable "alert_email" {
  description = "Email for alerts"
}