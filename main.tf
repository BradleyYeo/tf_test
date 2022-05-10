resource "aws_launch_configuration" "ec2_example" {
  image_id        = "ami-0bd6906508e74f692"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.sgRule.id]
  user_data       = file("aws-user-data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "sgRule" {
  name = "inbound-hello-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "alb" {
  name = "tf-example-alb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "deployer" {
  key_name   = "brad_hello_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDda9UjlkKRl0sONEScEafGYjd31vabgYQix7M+2UsgYK9QyJjzAt+D7/SsBqKAThMgV+9M3SHwrQzbN5TbH+cev/AKpLArq/iuTOTXC/53Ysg4dSfGrbjFJ8jk4n2wRrrIcq3MD6Zsag80GM/Z0ctz/i5yUwCGlcLFvVqW2aCyfDZvmSnGu33XXbDxFl7AcpU8/tO52Yu5GeaQg6h1Y5A+BeUmz5fmke2LL8LiI2+7SsLIuRmj7kASh7rgKdN7y8AZ+E4WMJV/9Hgn8+F07M+hoyAsu/zKds/T3EMmwMY/HsvODrhtYKzxDDH0uVdZ0FjgHbU8ZtSayyodphIwx/F2CRjvqiYLzJLLVawqwVF5Qo8Wn8jMBUL8j9r4qR7qiz46nX/rWKwV1k8BykRricfvKQjud/fgF2hyAD3P3dNg9W77RFRRzcNiv+VOfE8tu6yVsf+e9SOwor3wE6sSmGHiqaNoGPAg5WCyM13SwMqc3cl9s2XR9PvSyeP/3w0Wqy0= bradleyyeo@mbp"
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.ec2_example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 5

  tag {
    key                 = "Name"
    value               = "tf-asg-example"
    propagate_at_launch = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb" "lb_example" {
  name              = "tf-asg-example"
 load_balancer_type = "application"
  subnets           = data.aws_subnets.default.ids
  security_groups   = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb_example.arn
  port             = 80
  protocol         = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }

  }
}

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

output "alb_dns_name" {
  value       = aws_lb.lb_example.dns_name
  description = "The domain name of the load balancer"
}


