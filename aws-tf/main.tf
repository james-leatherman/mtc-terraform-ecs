# Root main.tf

module "infra" {
  source      = "./modules/infra"
  vpc_cidr    = "10.0.0.0/16"
  num_subnets = 2
  allowed_ips = ["96.248.41.102/32"]
}

module "app" {
  source              = "./modules/app"
  ecr_repository_name = "ui"
  app_path            = "ui"
  image_version       = "1.0.1"
}