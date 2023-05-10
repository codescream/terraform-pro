variable "region" {
  description = "aws account region"
  type        = string
  default     = "us-east-1"
}

variable "image-id" {
  description = "ami to use for ec2 instances"
  type        = string
  default     = "ami-016eb5d644c333ccb"
}

variable "instance-type" {
  description = "instance type to use for instances"
  type        = string
  default     = "t2.small"
}

variable "http-port" {
  description = "http port"
  type        = number
  default     = 80
}

variable "ssh-port" {
  description = "ssh port"
  type        = number
  default     = 22
}

variable "egress-port" {
  description = "outgoing port"
  type        = number
  default     = 0
}

variable "vpc-id" {
  description = "vpc to launch resources into"
  type        = string
  default     = "vpc-0e16a8bf8fea3b850"
}