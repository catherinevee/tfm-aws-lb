terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Data sources for existing VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Network Load Balancer
module "nlb" {
  source = "../../"

  name        = "network-lb-example"
  environment = "prod"
  vpc_id      = data.aws_vpc.default.id
  subnet_ids  = slice(data.aws_subnets.default.ids, 0, 2)

  load_balancer_type = "network"
  internal           = false

  target_groups = [
    {
      name                 = "tcp"
      port                 = 80
      protocol             = "TCP"
      target_type          = "instance"
      vpc_id               = data.aws_vpc.default.id
      health_check_protocol = "TCP"
      health_check_port     = "80"
      health_check_interval = 30
      health_check_timeout  = 10
      healthy_threshold     = 3
      unhealthy_threshold   = 3
      deregistration_delay  = 300
    },
    {
      name                 = "tls"
      port                 = 443
      protocol             = "TLS"
      target_type          = "instance"
      vpc_id               = data.aws_vpc.default.id
      health_check_protocol = "HTTPS"
      health_check_port     = "443"
      health_check_path     = "/health"
      health_check_interval = 30
      health_check_timeout  = 10
      healthy_threshold     = 3
      unhealthy_threshold   = 3
      deregistration_delay  = 300
    }
  ]

  listeners = [
    {
      port     = 80
      protocol = "TCP"
      default_action = {
        type = "forward"
        target_group_arn = null
      }
    },
    {
      port     = 443
      protocol = "TLS"
      default_action = {
        type = "forward"
        target_group_arn = null
      }
    }
  ]

  enable_cloudwatch_logs = true
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  tags = {
    Project     = "load-balancer-example"
    Environment = "production"
    Owner       = "terraform"
    Type        = "network"
  }
} 