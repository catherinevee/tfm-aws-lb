# ALB with WAF Integration Example

This example demonstrates how to use the AWS Load Balancer module to create an Application Load Balancer (ALB) with AWS WAF integration for enhanced security.

## Features

- WAF integration with managed rule sets
- IP rate limiting
- Enhanced security settings
- CloudWatch monitoring and metrics
- Comprehensive logging

## WAF Configuration

The WAF Web ACL includes:
1. IP Rate Limiting Rule:
   - Limits requests to 2000 per IP
   - Helps prevent DDoS attacks

2. AWS Managed Rules:
   - Common Rule Set for basic protection
   - Protects against common web exploits

## Usage

```hcl
module "alb" {
  source = "../../"

  name        = "example-waf-alb"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "application"
  internal          = false

  # Enable WAF
  enable_wafv2    = true
  wafv2_web_acl_arn = aws_wafv2_web_acl.this.arn

  # ... see main.tf for full configuration
}
```

## Prerequisites

- AWS account and credentials configured
- Terraform 1.13.0 or later
- AWS provider 6.2.0 or later

## Deployment

1. Initialize Terraform:
```bash
terraform init
```

2. Review the plan:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

## Security Features

- WAF protection with managed rules
- IP rate limiting
- CIDR-based access control
- HTTP/2 enabled
- CloudWatch monitoring

## Notes

- WAF rules can be customized based on requirements
- Consider adding custom rules for specific threats
- Monitor WAF metrics in CloudWatch
- Review and adjust IP rate limits as needed
