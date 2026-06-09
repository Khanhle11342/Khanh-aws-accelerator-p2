terraform {
  backend "s3" {
    bucket         = "terraform-state-khanhle"
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-lock"
  }
}
