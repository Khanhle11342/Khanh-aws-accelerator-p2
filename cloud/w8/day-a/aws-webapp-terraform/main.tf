module "vpc" {
  source = "./modules/vpc"
}

module "ec2" {
  source = "./modules/ec2"

  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
  ssh_cidr_block   = var.ssh_cidr_block
  instance_type    = var.instance_type
}

module "rds" {
  source = "./modules/rds"

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id
  db_username           = var.db_username
  db_password           = var.db_password
}

module "s3" {
  source = "./modules/s3"

  bucket_name = var.bucket_name
}
