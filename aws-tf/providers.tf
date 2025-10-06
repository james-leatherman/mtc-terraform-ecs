// Define the Terraform configuration and required providers
terraform {
  required_providers {
    // Specify the AWS provider and its version
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

// Configure the AWS provider
provider "aws" {
  // Set the AWS region where resources will be created
  region = "us-west-2"

  // Define default tags to be applied to all AWS resources
  default_tags {
    tags = {
      App = "mtc-app"
    }
  }
}