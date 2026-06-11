data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

}

resource "aws_instance" "k8s" {

  ami = data.aws_ami.ubuntu.id

  instance_type = "t3.small"

  key_name = aws_key_pair.k8s.key_name

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "minikube"
  }

}
