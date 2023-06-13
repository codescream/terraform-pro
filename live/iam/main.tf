provider "aws" {
  region = "us-east-1"
}
# resource "aws_iam_user" "terraform-user" {
#     count = length(var.names)
#     name = "${var.names[count.index]}"
# }

# module "iam-users" {
#     source = "../../modules/landing-zone/iam-user"

#     count = length(var.names)
#     user-name = var.names[count.index]
# }

module "iam-users" {
    source = "../../modules/landing-zone/iam-user"
    
    for_each = toset(var.names)
    user-name = each.value
}