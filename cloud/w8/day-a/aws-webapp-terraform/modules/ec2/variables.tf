variable "vpc_id" {
  description = "ID of the VPC where the EC2 security group will be created."
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet where the EC2 instance will be launched."
  type        = string
}

variable "ssh_cidr_block" {
  description = "CIDR block allowed to connect with SSH, for example 203.0.113.10/32."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}
