data "aws_key_pair" "devops" {
  key_name           = "devops"
  include_public_key = true
}

resource "aws_instance" "instance-pro" {
  ami           =  var.image-id
  instance_type = var.instance-type
  vpc_security_group_ids = [aws_security_group.pro-sg.id]
  key_name = data.aws_key_pair.devops.key_name

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

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-pro"
  }
}

resource "aws_security_group" "pro-sg" {
  name = "terraform-pro-sg"
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