resource "aws_lb" "hello" {

  name = "hello-alb"

  internal = false

  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb_sg.id
  ]

  subnets = data.aws_subnets.default.ids

}

resource "aws_lb_target_group" "hello" {

  name = "hello-tg"

  port = 30080

  protocol = "HTTP"

  target_type = "instance"

  vpc_id = data.aws_vpc.default.id

  health_check {

    path = "/"

    protocol = "HTTP"

    port = "30080"

  }

}

resource "aws_lb_target_group_attachment" "hello" {

  target_group_arn = aws_lb_target_group.hello.arn

  target_id = aws_instance.k8s.id

  port = 30080

}

resource "aws_lb_listener" "hello" {

  load_balancer_arn = aws_lb.hello.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.hello.arn

  }

}
