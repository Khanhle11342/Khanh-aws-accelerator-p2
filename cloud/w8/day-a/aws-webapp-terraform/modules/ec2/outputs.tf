output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "security_group_id" {
  value = aws_security_group.web.id
}
