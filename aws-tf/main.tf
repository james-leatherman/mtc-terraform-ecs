# Root Main.tf

# Fetch the OpenAI API key from AWS Secrets Manager
data "aws_secretsmanager_secret" "openai_api_key" {
  name = "OPENAI_API_KEY_2"
}

# Define local variables for application configurations
locals {
  apps = {
    # Configuration for the UI application
    ui = {
      ecr_repository_name = "ui"
      app_path            = "ui"
      image_version       = "1.0.1"
      app_name            = "ui"
      port                = 80
      is_public           = true
      path_pattern        = "/*"
      lb_priority         = 20
      healthcheck_path    = "/"
      envars              = [{}]
      secrets             = [{}]
    }
    # Configuration for the API application
    api = {
      ecr_repository_name = "api"
      app_path            = "api"
      image_version       = "1.0.1"
      app_name            = "api"
      port                = 5000
      is_public           = true
      path_pattern        = "/api/*"
      lb_priority         = 10
      healthcheck_path    = "/api/healthcheck"
      envars              = [{}]
      secrets             = [{ name = "OPENAI_API_KEY_2", valueFrom = data.aws_secretsmanager_secret.openai_api_key.arn }]
    }
  }
}

# Infrastructure module to create shared resources like VPC, subnets, and security groups
module "infra" {
  source      = "./modules/infra"
  vpc_cidr    = "10.0.0.0/16"
  num_subnets = 3
  allowed_ips = ["96.248.41.102/32"]
}

# Generate a Dockerfile for the UI application using a template
resource "local_file" "dockerfile" {
  content  = templatefile("modules/app/apps/templates/ui.tftpl", { build_args = { "backend_url" = module.infra.alb_dns_name } })
  filename = "modules/app/apps/ui/Dockerfile"
}

# Application module to deploy the UI and API applications
module "app" {
  source                = "./modules/app"
  for_each              = local.apps
  depends_on            = [local_file.dockerfile]
  ecr_repository_name   = each.value.ecr_repository_name
  app_path              = each.value.app_path
  image_version         = each.value.image_version
  app_name              = each.value.app_name
  port                  = each.value.port
  is_public             = each.value.is_public
  path_pattern          = each.value.path_pattern
  envars                = each.value.envars
  secrets               = each.value.secrets
  lb_priority           = each.value.lb_priority
  healthcheck_path      = each.value.healthcheck_path
  execution_role_arn    = module.infra.execution_role_arn
  app_security_group_id = module.infra.app_security_group_id
  subnets               = module.infra.public_subnets
  cluster_arn           = module.infra.cluster_arn
  vpc_id                = module.infra.vpc_id
  alb_listener_arn      = module.infra.alb_listener_arn
}

# Output the DNS name of the ALB for accessing the deployed applications
output "alb_dns_name" {
  value = "http://${module.infra.alb_dns_name}"
}