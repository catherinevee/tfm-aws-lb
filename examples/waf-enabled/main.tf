provider "aws" {
  region = "us-west-2"
}

# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "waf-example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "this" {
  name        = "example-waf-acl"
  description = "Example WAF ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "BlockIPRule"
    priority = 1

    override_action {
      none {}
    }

    statement {
      ip_rate_based {
        limit = 2000
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "BlockIPRuleMetric"
      sampled_requests_enabled  = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "ExampleWebACLMetric"
    sampled_requests_enabled  = true
  }

  tags = {
    Environment = "dev"
    Example     = "waf-enabled"
  }
}

# Application Load Balancer with WAF
module "alb" {
  source = "../.."

  name        = "example-waf-alb"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "application"
  internal          = false

  target_groups = [
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
    }
  ]

  # Enable WAF
  enable_wafv2    = true
  wafv2_web_acl_arn = aws_wafv2_web_acl.this.arn

  # Enhanced security settings
  allowed_ipv4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  enable_http2            = true

  # Enable monitoring
  create_dashboard = true
  create_alarms   = true
  error_threshold = 5
  alarm_actions   = [] # Add SNS topic ARN for notifications

  tags = {
    Environment = "dev"
    Example     = "waf-enabled"
  }
}

# Outputs
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.alb.load_balancer_dns_name
}

output "waf_web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.id
}

output "waf_web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.arn
}
