# ALB with HTTPS Example

This example demonstrates how to use the AWS Load Balancer module to create an Application Load Balancer (ALB) with HTTPS support and automatic HTTP to HTTPS redirection.

## Features

- HTTPS listener with TLS 1.3 support
- Automatic HTTP to HTTPS redirection
- ACM certificate integration
- Enhanced security settings
- Access logging to S3

## Usage

```hcl
module "alb" {
  source = "../../"

  name        = "example-alb-https"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "application"
  internal          = false

  # ... see main.tf for full configuration
}
```

## Prerequisites

- AWS account and credentials configured
- Terraform 1.13.0 or later
- AWS provider 6.2.0 or later
- Domain name for SSL certificate
- S3 bucket for access logs

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

## Notes

- Replace `example.com` with your actual domain name
- Configure DNS validation for the ACM certificate
- Update the S3 bucket name for access logs
- The ALB redirects all HTTP traffic to HTTPS
- Uses modern TLS security policy: ELBSecurityPolicy-TLS13-1-2-2021-06
