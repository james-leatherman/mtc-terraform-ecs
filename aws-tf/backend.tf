# terraform {
#   backend "s3" {
#     bucket       = ""
#     key          = "terraform.tfstate"
#     region       = "us-west-2"
#     use_lockfile = true
#   }
# }

terraform {
  cloud {

    organization = "james-leatherman"

    workspaces {
      name = "state-buckets"
    }
  }
}