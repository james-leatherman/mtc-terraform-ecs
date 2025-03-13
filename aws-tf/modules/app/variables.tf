variable "ecr_repository_name" {
  description = "The name of the ECR repository"
  type        = string
}

variable "app_path" {
  description = "The path to the app to build"
  type        = string
}

variable "image_version" {
  description = "The version of the image to build"
  type        = string
}

variable "app_name" {
  description = "The name of the app"
  type        = string
}

variable "port" {
  description = "The port the app listens on"
  type        = number
}

variable "execution_role_arn" {
  description = "The ARN of the ECS execution role"
  type        = string
}

variable "app_security_group_id" {
  description = "The ID of the security group"
  type        = string
}

variable "subnets" {
  description = "The subnets to use"
  type        = list(string)
}

variable "is_public" {
  description = "Whether the load balancer is public"
  type        = bool
  default     = true
}

variable "cluster_arn" {
  description = "The ARN of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}