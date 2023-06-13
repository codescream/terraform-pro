data "aws_vpc" "my_vpc" {
  id = var.my_vpc
}

resource "aws_subnet" "terraform-pro" {
  vpc_id                  = data.aws_vpc.my_vpc.id
  cidr_block              = "10.0.0.128/26"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "Test-vpc-Private-subnet1"
  }
}

resource "aws_subnet" "terraform-pro1" {
  vpc_id                  = data.aws_vpc.my_vpc.id
  cidr_block              = "10.0.0.192/26"
  availability_zone       = "us-east-1d"
  map_public_ip_on_launch = false

  tags = {
    Name = "Test-vpc-Private-subnet2"
  }
}

resource "aws_db_subnet_group" "db-subnet" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.terraform-pro.id, aws_subnet.terraform-pro1.id]
}

resource "aws_db_instance" "pro-db" {
  identifier_prefix    = "terraform-pro-db"
  engine               = "mysql"
  allocated_storage    = 10
  instance_class       = "db.t2.micro"
  skip_final_snapshot  = true
  db_name              = "terraform_pro_db"
  db_subnet_group_name = aws_db_subnet_group.db-subnet.name
  # How should we set the username and password?
  username = var.db_username
  password = var.db_password
}

# terraform {
#   backend "s3" {
#     # Partial configuration. Other settings
#     # will be passed in from a file via -backend-config to 
#     # 'terraform init'
#     # Replace this with your bucket name!
#     # bucket = "terraform-pro-s3-bkt"
#     key    = "stage/data-stores/mysql/terraform.tfstate"
#     # region = "us-east-1"

#     # # Replace this with your DynamoDB table name!
#     # dynamodb_table = "terraform-pro-locks"
#     # encrypt        = true
#   }
# }

# terraform {
#   backend "local" {
#     path = "./terraform.tfstate"
#   }
# }