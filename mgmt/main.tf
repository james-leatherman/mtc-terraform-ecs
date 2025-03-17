terraform {
  cloud {

    organization = "james-leatherman"

    workspaces {
      name = "state-buckets"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  buckets = {
    "dev"  = "mtc-app-state-leatherman"
    "prod" = "mtc-app-state-leatherman-2"
  }
}

import {
  for_each = local.buckets
  to       = aws_s3_bucket.this[each.key]
  id       = each.value
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets
}