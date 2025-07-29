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

# S3 bucket for access logs
resource "aws_s3_bucket" "lb_logs" {
  bucket = "my-lb-logs-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# WAF Web ACL for additional security
resource "aws_wafv2_web_acl" "main" {
  name        = "alb-waf-web-acl"
  description = "WAF Web ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

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
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "alb-waf-web-acl-metric"
    sampled_requests_enabled   = true
  }
}

# Advanced Application Load Balancer with SSL/TLS
module "alb_advanced" {
  source = "../../"

  name        = "advanced-alb-example"
  environment = "prod"
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
      health_check_path    = "/health"
      health_check_port    = "traffic-port"
      health_check_protocol = "HTTP"
      health_check_interval = 30
      health_check_timeout  = 5
      healthy_threshold     = 2
      unhealthy_threshold   = 2
      matcher               = "200"
      deregistration_delay  = 300
      stickiness = {
        type            = "lb_cookie"
        cookie_duration = 86400
        enabled         = true
      }
    },
    {
      name                 = "api"
      port                 = 8080
      protocol             = "HTTP"
      target_type          = "instance"
      vpc_id               = data.aws_vpc.default.id
      health_check_path    = "/api/health"
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
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    },
    {
      port           = 443
      protocol       = "HTTPS"
      ssl_policy     = "ELBSecurityPolicy-TLS-1-2-2017-01"
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
      default_action = {
        type = "forward"
        target_group_arn = null
      }
      rules = [
        {
          priority = 100
          action = {
            type = "forward"
            target_group_arn = null
          }
          condition = {
            field  = "path-pattern"
            values = ["/api/*"]
          }
        }
      ]
    }
  ]

  access_logs = {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  waf_web_acl_arn = aws_wafv2_web_acl.main.arn

  enable_cloudwatch_logs = true
  enable_deletion_protection = true
  enable_cross_zone_load_balancing = true
  enable_http2 = true
  idle_timeout = 60

  tags = {
    Project     = "load-balancer-example"
    Environment = "production"
    Owner       = "terraform"
    CostCenter  = "engineering"
  }
} 