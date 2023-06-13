data "aws_key_pair" "devops" {
  key_name           = var.keypair
  include_public_key = true
}

locals {
  http_port    = 80
  ssh_port     = 22
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  http_protocol = "HTTP"
}

resource "aws_launch_configuration" "instance-lc-asg" {
  image_id        = var.image-id
  instance_type   = var.instance-type
  security_groups = [aws_security_group.pro-ec2-sg.id]
  key_name        = data.aws_key_pair.devops.key_name
  # associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install httpd -y
              systemctl enable httpd
              systemctl start httpd
              echo "Hello, World" > /var/www/html/index.html
              systemctl restart httpd
              firewall-cmd --permanent --add-port=80/tcp && firewall-cmd --reload
              systemctl restart firewalld
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "pro-vpc" {
  id = var.vpc-id
}

data "aws_security_group" "default-vpc-sg" {
  vpc_id = data.aws_vpc.pro-vpc.id

  filter {
    name = "group-name"
    values = ["default"]
  }
}

data "aws_subnets" "vpc-subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.pro-vpc.id]
  }

  filter {
    name = "map-public-ip-on-launch"
    values = ["true"]
  }
}

resource "aws_autoscaling_group" "pro-asg" {
  name = "${var.cluster-name}-asg"
  launch_configuration = aws_launch_configuration.instance-lc-asg.name
  vpc_zone_identifier  = data.aws_subnets.vpc-subnets.ids
  target_group_arns    = [aws_lb_target_group.pro-tg.arn]

  health_check_type = "ELB"
  min_size          = 3
  max_size          = 3

  tag {
    key                 = "Name"
    value               = "terraform-pro-asg"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "pro-alb-sg" {
  name   = "${var.cluster-name}-alb-sg"
  vpc_id = data.aws_vpc.pro-vpc.id

  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  ingress {
    from_port   = local.ssh_port
    to_port     = local.ssh_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  egress {
    from_port        = local.any_port
    to_port          = local.any_port
    protocol         = local.any_protocol
    cidr_blocks      = local.all_ips
    ipv6_cidr_blocks = local.ipv6_cidr_blocks
  }
}

resource "aws_security_group" "pro-ec2-sg" {
  name   = "${var.cluster-name}-ec2-sg"
  vpc_id = data.aws_vpc.pro-vpc.id

  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.ssh_port
    security_groups = ["${aws_security_group.pro-alb-sg.id}"]
  }

  ingress {
    from_port   = local.ssh_port
    to_port     = local.ssh_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  egress {
    from_port        = local.any_port
    to_port          = local.any_port
    protocol         = local.any_protocol
    cidr_blocks      = local.all_ips
    ipv6_cidr_blocks = local.ipv6_cidr_blocks
  }
}

resource "aws_lb" "pro-lb" {
  name               = "${var.cluster-name}-pro-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pro-alb-sg.id, data.aws_security_group.default-vpc-sg.id]
  subnets            = data.aws_subnets.vpc-subnets.ids
}

resource "aws_lb_listener" "pro-lb-listener" {
  load_balancer_arn = aws_lb.pro-lb.arn
  port              = local.http_port
  protocol          = local.http_protocol

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "pro-tg" {
  name     = "${var.cluster-name}-pro-tg"
  port     = local.http_port
  protocol = local.http_protocol
  vpc_id   = data.aws_vpc.pro-vpc.id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200"
    path                = "/"
    protocol            = local.http_protocol
    timeout             = 10
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "pro-listener-rule" {
  listener_arn = aws_lb_listener.pro-lb-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pro-tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

output "lb-public-dns-name" {
  value       = aws_lb.pro-lb.dns_name
  description = "DNS name of the load balancer"
}