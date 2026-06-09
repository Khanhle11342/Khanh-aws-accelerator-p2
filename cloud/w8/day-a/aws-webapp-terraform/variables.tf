variable "region" {
  description = "AWS region where resources will be created."
  type        = string
}

variable "ssh_cidr_block" {
  description = "CIDR block allowed to connect to the EC2 instance with SSH."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "db_username" {
  description = "Master username for the MySQL database."
  type        = string
}

variable "db_password" {
  description = "Master password for the MySQL database."
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "Name of the S3 bucket for static assets."
  type        = string
}
