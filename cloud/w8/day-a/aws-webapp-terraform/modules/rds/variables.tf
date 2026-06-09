variable "vpc_id" {
  description = "ID of the VPC where the RDS security group will be created."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "EC2 security group ID allowed to connect to MySQL."
  type        = string
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
