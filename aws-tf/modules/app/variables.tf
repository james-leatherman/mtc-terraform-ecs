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