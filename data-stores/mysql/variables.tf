variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "my_vpc" {
  description = "vpc to use"
  type        = string
  default     = "vpc-07fe0e70d536180a1"
}