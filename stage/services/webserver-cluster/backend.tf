# terraform {
#   backend "s3" {
#     # Replace this with your bucket name!
#     bucket         = "terraform-pro-s3-bkt"
#     key            = "global/s3/terraform.tfstate"
#     region         = "us-east-1"

#     # Replace this with your DynamoDB table name!
#     dynamodb_table = "terraform-pro-locks"
#     encrypt        = true
#   }
# }

# OR

# terraform {
#   backend "local" {
#     # location of local terraform state file
#     path = "./terraform.tfstate"
#   }
# }