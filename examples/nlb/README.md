# Network Load Balancer Example

This example demonstrates how to use the AWS Load Balancer module to create a Network Load Balancer (NLB) with TCP traffic handling.

## Features

- Network Load Balancer deployment
- TCP protocol handling on port 80
- Cross-zone load balancing enabled
- Health checks using TCP protocol
- IP-based target group

## Usage

```hcl
module "nlb" {
  source = "../../"

  name        = "example-nlb"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  load_balancer_type = "network"
  internal          = false

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

## Notes

- This example creates a public NLB that can handle TCP traffic
- Cross-zone load balancing is enabled for better availability
- The target group uses IP-based targets for flexibility
