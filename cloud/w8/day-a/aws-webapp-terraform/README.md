# AWS Web App Terraform

Terraform project for deploying a simple web application architecture on AWS.

## Architecture

- VPC with public and private subnets
- EC2 web server in the public subnet
- RDS MySQL database in private subnets
- S3 bucket for static assets with versioning enabled
- Security groups allowing only required traffic
- Remote Terraform state stored in S3 with DynamoDB locking

The EC2 instance installs Nginx with user data and serves:

```text
Khanh XB-DN26-001 Hello Xbrain
```

## Project Structure

```text
.
├── backend.tf
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── backend-bootstrap
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── outputs.tf
└── modules
    ├── vpc
    ├── ec2
    ├── rds
    └── s3
```

## Prerequisites

- Terraform installed
- AWS credentials configured
- An AWS account with permission to create VPC, EC2, RDS, S3, and DynamoDB resources

## 1. Create Backend Resources

The S3 backend bucket and DynamoDB lock table must exist before initializing the main Terraform project.

```powershell
cd backend-bootstrap
terraform init
terraform apply
```

This creates:

- S3 bucket: `terraform-state-khanhle`
- DynamoDB table: `terraform-lock`

## 2. Configure Variables

Create your local `terraform.tfvars` from the example:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Update:

- `db_password`
- `bucket_name`
- `ssh_cidr_block`

Use your public IP for SSH access:

```hcl
ssh_cidr_block = "YOUR_PUBLIC_IP/32"
```

## 3. Deploy

```powershell
terraform init
terraform plan
terraform apply
```

## Outputs

After apply, Terraform prints:

- `ec2_public_ip`
- `rds_endpoint`
- `s3_bucket_name`

Open the web app in a browser:

```text
http://<ec2_public_ip>
```

## Security Notes

- Do not commit `terraform.tfvars`.
- Do not commit `.terraform/` or `*.tfstate` files.
- RDS allows MySQL traffic only from the EC2 security group.
- EC2 allows HTTP from anywhere and SSH only from `ssh_cidr_block`.

## Cleanup

Destroy the main application first:

```powershell
terraform destroy
```

Then destroy backend resources if they are no longer needed:

```powershell
cd backend-bootstrap
terraform destroy
```
