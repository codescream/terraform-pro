data "aws_key_pair" "devops" {
  key_name           = "devops"
  include_public_key = true
}

resource "aws_launch_configuration" "instance-lc-asg" {
  image_id  = var.image-id
  instance_type   = var.instance-type
  security_groups = [aws_security_group.pro-sg.id]
  key_name        = data.aws_key_pair.devops.key_name

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

data "aws_subnets" "vpc-subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.pro-vpc.id]
  }
}

resource "aws_autoscaling_group" "pro-asg" {
  launch_configuration = aws_launch_configuration.instance-lc-asg.name
  vpc_zone_identifier  = data.aws_subnets.vpc-subnets.ids
  min_size             = 2
  max_size             = 2

  tag {
    key                 = "Name"
    value               = "terraform-pro-asg"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "pro-sg" {
  name   = "terraform-pro-sg"
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

# output "ec2-public-ip" {
#   value       = aws_instance.instance-pro.public_ip
#   description = "the public ip of instance"
# }