data "aws_key_pair" "devops" {
  key_name           = "devops"
  include_public_key = true
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
              echo "${data.terraform_remote_state.db.outputs.address}" >> /var/www/html/index.html
              echo "${data.terraform_remote_state.db.outputs.port}" >> /var/www/html/index.html
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

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "terraform-pro-s3-bkt"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_autoscaling_group" "pro-asg" {
  name = "terraform-pro-asg"
  launch_configuration = aws_launch_configuration.instance-lc-asg.name
  vpc_zone_identifier  = data.aws_subnets.vpc-subnets.ids
  target_group_arns    = [aws_lb_target_group.pro-tg.arn]

  health_check_type = "ELB"
  min_size          = 2
  max_size          = 2

  tag {
    key                 = "Name"
    value               = "terraform-pro-asg"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "pro-alb-sg" {
  name   = "pro-alb-sg"
  vpc_id = data.aws_vpc.pro-vpc.id

  ingress {
    from_port   = var.http-port
    to_port     = var.http-port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.ssh-port
    to_port     = var.ssh-port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = var.egress-port
    to_port          = var.egress-port
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "pro-ec2-sg" {
  name   = "pro-ec2-sg"
  vpc_id = data.aws_vpc.pro-vpc.id

  ingress {
    from_port   = var.http-port
    to_port     = var.http-port
    protocol    = "tcp"
    security_groups = ["${aws_security_group.pro-alb-sg.id}"]
  }

  ingress {
    from_port   = var.ssh-port
    to_port     = var.ssh-port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = var.egress-port
    to_port          = var.egress-port
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "pro-lb" {
  name               = "terraform-pro-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pro-alb-sg.id, data.aws_security_group.default-vpc-sg.id]
  subnets            = data.aws_subnets.vpc-subnets.ids
}

resource "aws_lb_listener" "pro-lb-listener" {
  load_balancer_arn = aws_lb.pro-lb.arn
  port              = "80"
  protocol          = "HTTP"

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
  name     = "terraform-pro-tg"
  port     = var.http-port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.pro-vpc.id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200"
    path                = "/"
    protocol            = "HTTP"
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