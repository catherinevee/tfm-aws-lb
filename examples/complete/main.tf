provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "lb-example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  
  enable_ipv6             = true
  assign_ipv6_address_on_creation = true
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name  = "example.com"
  zone_id      = "Z12345678"  # Replace with your Route53 zone ID

  wait_for_validation = true
}

module "load_balancer" {
  source = "../.."

  name        = "complete-example"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "application"
  internal          = false

  enable_deletion_protection = true
  enable_http2             = true
  enable_wafv2            = true
  
  allowed_ipv4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  enable_ipv6              = true
  allowed_ipv6_cidr_blocks = [module.vpc.vpc_ipv6_cidr_block]

  # Enhanced logging
  enable_cloudwatch_logs         = true
  cloudwatch_log_retention_days = 30
  
  # Access logs to S3
  access_logs_enabled = true
  access_logs_bucket  = "my-lb-logs"  # Replace with your S3 bucket
  access_logs_prefix  = "logs/complete-example"

  # Tags
  tags = {
    Project     = "Demo"
    CostCenter = "123456"
  }
}
