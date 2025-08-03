provider "aws" {
  region = "us-west-2"
}

# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "nlb-example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# Network Load Balancer
module "nlb" {
  source = "../.."

  name        = "example-nlb"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "network"
  internal          = false

  target_groups = [
    {
      name             = "tcp-example"
      port             = 80
      protocol         = "TCP"
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval           = 30
        port               = "traffic-port"
        protocol          = "TCP"
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  ]

  listeners = [
    {
      port     = 80
      protocol = "TCP"
      default_action = {
        type             = "forward"
        target_group_key = "tcp-example"
      }
    }
  ]

  enable_cross_zone_load_balancing = true

  tags = {
    Environment = "dev"
    Example     = "nlb"
  }
}

# Output the NLB DNS name
output "nlb_dns_name" {
  description = "The DNS name of the NLB"
  value       = module.nlb.load_balancer_dns_name
}
