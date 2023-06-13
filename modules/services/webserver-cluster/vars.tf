variable "region" {
  description = "aws account region"
  type        = string
  default     = "us-east-2"
}

variable "image-id" {
  description = "ami to use for ec2 instances"
  type        = string
  default     = "ami-016eb5d644c333ccb"
  # default = "ami-02b8534ff4b424939"
}

variable "instance-type" {
  description = "instance type to use for instances"
  type        = string
  default     = "t2.small"
}

# variable "http-port" {
#   description = "http port"
#   type        = number
#   default     = 80
# }

# variable "ssh-port" {
#   description = "ssh port"
#   type        = number
#   default     = 22
# }

# variable "egress-port" {
#   description = "outgoing port"
#   type        = number
#   default     = 0
# }

variable "vpc-id" {
  description = "vpc to launch our resources into"
  type        = string
  default     = "vpc-07fe0e70d536180a1"
}

variable "cluster-name" {
  description = "The name to use for all the cluster resources"
  type  = string
}

# variable "db_remote_state_bucket" {
#   description = "The name of the S3 bucket for the DB remote state"
#   type        = string
# }

# variable "db_remote_state_key" {
#   description = "The path for the DB remote state in S3"
#   type        = string
# }

variable "keypair" {
  description = "keypair for instances"
  type = string
}