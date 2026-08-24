variable "aws_region" {
  description = "Please enter the AWS Region for deployment (Default: us-east-1): "
  type    = string
  default = "us-east-1"
}

variable "my_ip" {
  description = "Please enter your public IP for SSH whitelist: "
  type        = string

  validation {
  # This regex checks for 4 numbers (0-255) separated by periods
  condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.my_ip))
  error_message = "The IP address must be a valid IPv4 address (e.g., 198.51.100.12) without any subnet mask or spaces."
  }
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro" # Free Tier eligible in most regions
}

variable "key_name" {
  description = "Name of the existing AWS Key Pair or key resource identifier"
  type        = string
  default     = "mostepic_key"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_key" {
  description = "The raw public SSH key string"
  type        = string
  sensitive   = true
}