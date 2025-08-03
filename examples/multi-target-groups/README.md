# ALB with Multiple Target Groups Example

This example demonstrates how to use the AWS Load Balancer module to create an Application Load Balancer (ALB) with multiple target groups and path-based routing.

## Features

- Multiple target groups for different services
- Path-based routing using listener rules
- Health checks for each target group
- CloudWatch dashboard and alarms
- Comprehensive monitoring

## Usage

```hcl
module "alb" {
  source = "../../"

  name        = "example-multi-tg"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "application"
  internal          = false

  # ... see main.tf for full configuration
}
```

## Target Groups

1. Web Application (Default):
   - Path: /* (default)
   - Port: 80

2. API v1:
   - Path: /api/v1/*
   - Port: 8080

3. API v2:
   - Path: /api/v2/*
   - Port: 8081

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

## Monitoring

This example includes:
- CloudWatch dashboard for monitoring metrics
- Alarms for error rates
- Target group health monitoring

## Notes

- Each target group has its own health check configuration
- Path-based routing directs traffic to appropriate services
- Consider adding SNS topics for alarm notifications
