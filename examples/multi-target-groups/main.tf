provider "aws" {
  region = "us-west-2"
}

# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "multi-tg-example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# Application Load Balancer with Multiple Target Groups
module "alb" {
  source = "../.."

  name        = "example-multi-tg"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "application"
  internal          = false

  target_groups = [
    {
      name             = "api-v1"
      port             = 8080
      protocol         = "HTTP"
      target_type      = "ip"
      health_check = {
        path               = "/api/v1/health"
        port               = "traffic-port"
        matcher           = "200"
      }
    },
    {
      name             = "api-v2"
      port             = 8081
      protocol         = "HTTP"
      target_type      = "ip"
      health_check = {
        path               = "/api/v2/health"
        port               = "traffic-port"
        matcher           = "200"
      }
    },
    {
      name             = "web-app"
      port             = 80
      protocol         = "HTTP"
      target_type      = "ip"
      health_check = {
        path               = "/health"
        port               = "traffic-port"
        matcher           = "200"
      }
    }
  ]

  listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = "web-app"
      }
      rules = [
        {
          priority = 1
          conditions = [
            {
              path_pattern = ["/api/v1/*"]
            }
          ]
          actions = [
            {
              type             = "forward"
              target_group_key = "api-v1"
            }
          ]
        },
        {
          priority = 2
          conditions = [
            {
              path_pattern = ["/api/v2/*"]
            }
          ]
          actions = [
            {
              type             = "forward"
              target_group_key = "api-v2"
            }
          ]
        }
      ]
    }
  ]

  # Enable monitoring
  create_dashboard = true
  create_alarms   = true
  error_threshold = 5
  alarm_actions   = [] # Add SNS topic ARN for notifications

  tags = {
    Environment = "dev"
    Example     = "multi-target-groups"
  }
}

# Outputs
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.alb.load_balancer_dns_name
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value       = module.alb.target_group_arns
}
