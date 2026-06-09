data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "web" {
  name        = "webapp-ec2-sg"
  description = "Allow SSH and HTTP access to the web instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr_block]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webapp-ec2-sg"
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>Khanh Xbrain</title>
        <style>
          body {
            align-items: center;
            display: flex;
            font-family: Arial, sans-serif;
            justify-content: center;
            margin: 0;
            min-height: 100vh;
          }
          h1 {
            font-size: 42px;
            font-weight: 700;
          }
        </style>
      </head>
      <body>
        <h1>Khanh XB-DN26-001 Hello Xbrain</h1>
      </body>
    </html>
    HTML
    systemctl start nginx
  EOF

  tags = {
    Name = "webapp-instance"
  }
}
