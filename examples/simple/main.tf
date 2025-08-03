provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "lb-example-simple"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "load_balancer" {
  source = "../.."

  name        = "simple-example"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "application"
  internal          = false

  target_groups = [
    {
      name             = "simple-tg"
      port             = 80
      protocol         = "HTTP"
      target_type      = "ip"
      health_check = {
        path = "/health"
        port = "traffic-port"
      }
    }
  ]

  listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = "simple-tg"
      }
    }
  ]

  tags = {
    Project = "Simple Demo"
  }
}
