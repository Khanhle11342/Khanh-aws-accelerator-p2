resource "aws_security_group" "db" {
  name        = "webapp-rds-sg"
  description = "Allow MySQL access from the EC2 security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webapp-rds-sg"
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "webapp-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "webapp-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier             = "webapp-mysql"
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "webapp-mysql"
  }
}
