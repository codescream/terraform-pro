provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "instance-pro" {
  ami           =  "ami-016eb5d644c333ccb" 
  instance_type = "t2.micro"

  tags = {
    Name = "terraform-pro"
  }
}