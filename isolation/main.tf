resource "aws_instance" "isolation-ec2" {
  ami = "ami-016eb5d644c333ccb"
  instance_type = "t2.micro"
}

terraform {
  backend "s3" {
    bucket  =   "terraform-pro-s3-bkt"
    key = "workspaces-example/terraform.tfstate"
    region  =   "us-east-1"

    dynamodb_table  =   "terraform-pro-locks"
    encrypt = true
  }
}