variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "num_subnets" {
  description = "The number of subnets to create"
  type        = number
}

variable "allowed_ips" {
  description = "The CIDR block for allowed IPs"
  type        = set(string)
}
