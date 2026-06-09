output "alb_dns_name" {

  value = aws_lb.hello.dns_name

}

output "app_url" {
  value = "http://${aws_lb.hello.dns_name}"
}
