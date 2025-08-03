provider "aws" {
  region = "us-west-2"
}

# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "alb-https-example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# ACM Certificate
resource "aws_acm_certificate" "this" {
  domain_name       = "example.com"
  validation_method = "DNS"

  tags = {
    Environment = "dev"
    Example     = "alb-https"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer with HTTPS
module "alb" {
  source = "../.."

  name        = "example-alb-https"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "application"
  internal          = false

  target_groups = [
    {
      name             = "app-example"
      port             = 80
      protocol         = "HTTP"
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval           = 30
        path               = "/health"
        port               = "traffic-port"
        protocol          = "HTTP"
        matcher           = "200"
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  ]

  listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate.this.arn
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      default_action = {
        type             = "forward"
        target_group_key = "app-example"
      }
    },
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
  ]

  # Enhanced security settings
  enable_http2    = true
  idle_timeout    = 60

  # Access logs to S3
  access_logs_enabled = true
  access_logs_bucket  = "my-alb-logs" # Replace with your bucket
  access_logs_prefix  = "alb-https"

  tags = {
    Environment = "dev"
    Example     = "alb-https"
  }
}

# Outputs
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.alb.load_balancer_dns_name
}

output "certificate_arn" {
  description = "The ARN of the certificate"
  value       = aws_acm_certificate.this.arn
}
