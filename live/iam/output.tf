# output "iam-arns" {
#   description = "arns for iam users"
#   value = module.iam-users[*].iam-user-arn
# }

# output "list-users" {
#     value = module.iam-users.all-users
# }

output "arn-list" {
    value = values(module.iam-users)[*].all-users
}