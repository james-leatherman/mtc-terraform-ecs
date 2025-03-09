variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "num_subnets" {
  description = "The number of subnets to create"
  type        = number
}