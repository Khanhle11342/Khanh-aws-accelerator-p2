variable "region" {
  description = "AWS region where the backend resources will be created."
  type        = string
  default     = "ap-southeast-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform remote state."
  type        = string
  default     = "terraform-state-khanhle"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking."
  type        = string
  default     = "terraform-lock"
}
