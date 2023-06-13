# output "iam-user-arn" {
#     description = "arn of iam user"
#     value = aws_iam_user.terraform-iam-user.arn
# }

output "all-users" {
    value = aws_iam_user.terraform-iam-user
}

output "user_arn" {
    value = aws_iam_user.terraform-iam-user.arn
}