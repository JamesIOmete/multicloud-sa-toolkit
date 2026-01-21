terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  base_name  = var.name_prefix != "" ? var.name_prefix : "mcsa-uc04-${var.env}"
  sandbox_id = lower(replace(var.sandbox_id, " ", "-"))
  tags = merge({
    toolkit    = "multicloud-sa-toolkit",
    use_case   = "04-ephemeral-sandbox",
    env        = var.env,
    owner      = var.owner,
    managed_by = "terraform",
    sandbox_id = local.sandbox_id
  }, var.additional_tags)

  alert_topic_arn = var.alert_topic_arn != "" ? var.alert_topic_arn : var.fallback_alert_topic_arn
}

module "networking" {
  source = "../modules/networking"

  base_name            = local.base_name
  sandbox_id           = local.sandbox_id
  env                  = var.env
  owner                = var.owner
  additional_tags      = var.additional_tags
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
}

module "fargate" {
  source = "../modules/fargate"

  base_name                 = local.base_name
  sandbox_id                = local.sandbox_id
  env                       = var.env
  owner                     = var.owner
  additional_tags           = var.additional_tags
  aws_region                = var.aws_region
  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_subnet_ids        = module.networking.private_subnet_ids
  security_group_id         = module.networking.security_group_id
  container_image           = var.container_image
  container_port            = var.container_port
  desired_count             = var.desired_count
  task_cpu                  = var.task_cpu
  task_memory               = var.task_memory
  enable_container_insights = var.enable_container_insights
  log_retention_days        = var.task_log_retention_days
}

module "cost_controls" {
  source = "../modules/cost-controls"

  base_name                   = local.base_name
  sandbox_id                  = local.sandbox_id
  env                         = var.env
  owner                       = var.owner
  additional_tags             = var.additional_tags
  monthly_budget_amount       = var.monthly_budget_amount
  budget_threshold_percent    = var.budget_threshold_percent
  anomaly_threshold_amount    = var.anomaly_threshold_amount
  enable_cost_anomaly_monitor = var.enable_cost_anomaly_monitor
  alert_topic_arn             = local.alert_topic_arn
}

module "metadata" {
  source = "../modules/metadata"

  base_name             = local.base_name
  sandbox_id            = local.sandbox_id
  env                   = var.env
  owner                 = var.owner
  additional_tags       = var.additional_tags
  metadata_table_name   = var.metadata_table_name
  create_metadata_table = var.create_metadata_table
  ttl_hours             = var.ttl_hours
}
