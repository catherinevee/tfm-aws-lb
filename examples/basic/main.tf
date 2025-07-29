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

# Basic Application Load Balancer
module "alb_basic" {
  source = "../../"

  name        = "basic-alb-example"
  environment = "dev"
  vpc_id      = data.aws_vpc.default.id
  subnet_ids  = slice(data.aws_subnets.default.ids, 0, 2)

  load_balancer_type = "application"
  internal           = false

  target_groups = [
    {
      name                 = "web"
      port                 = 80
      protocol             = "HTTP"
      target_type          = "instance"
      vpc_id               = data.aws_vpc.default.id
      health_check_path    = "/"
      health_check_port    = "traffic-port"
      health_check_protocol = "HTTP"
      health_check_interval = 30
      health_check_timeout  = 5
      healthy_threshold     = 2
      unhealthy_threshold   = 2
      matcher               = "200"
      deregistration_delay  = 300
    }
  ]

  listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "forward"
        target_group_arn = null
      }
    }
  ]

  enable_cloudwatch_logs = true
  enable_deletion_protection = false

  tags = {
    Project     = "load-balancer-example"
    Environment = "development"
    Owner       = "terraform"
  }
} 