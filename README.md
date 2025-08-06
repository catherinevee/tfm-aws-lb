# AWS Load Balancer Terraform Module

Terraform module for creating AWS Application Load Balancers (ALB) and Network Load Balancers (NLB) with security, monitoring, and high availability features.

## Features

- Application Load Balancer (ALB) and Network Load Balancer (NLB) support
- Cross-zone load balancing and multi-AZ deployment
- Security groups with WAF integration and SSL/TLS termination
- CloudWatch logs, metrics, and alarms
- Multiple target groups, listeners, and routing rules
- Resource tagging for cost allocation and compliance

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.13.0 |
| aws | 6.2.0 |

## Resource Architecture

| Resource Type | Purpose | Default Configuration |
|--------------|---------|----------------------|
| `aws_lb` | Main load balancer | Type: application/network based on var.load_balancer_type |
| `aws_security_group` | Load balancer security group | Created if no security_group_ids provided |
| `aws_cloudwatch_log_group` | Load balancer logs | Created if enable_cloudwatch_logs = true |
| `aws_lb_listener` | Load balancer listeners | HTTP/HTTPS based on configuration |
| `aws_lb_target_group` | Target groups for routing | Created based on target_groups variable |
| `aws_lb_listener_rule` | Routing rules | Created based on listener_rules variable |
| `aws_wafv2_web_acl_association` | WAFv2 integration | Created if enable_wafv2 = true |

## Usage

### Basic Application Load Balancer

```hcl
module "alb" {
  source = "./tfm-aws-lb"

  name        = "my-app-alb"
  environment = "prod"
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]

  load_balancer_type = "application"
  internal           = false

  target_groups = [
    {
      name        = "web"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      vpc_id      = "vpc-12345678"
      health_check_path = "/health"
    }
  ]

  listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "forward"
        target_group_arn = null
      }
    }
  ]

  tags = {
    Project     = "my-app"
    Environment = "production"
  }
}
```

### Load Balancer with SSL/TLS

```hcl
module "alb_ssl" {
  source = "./tfm-aws-lb"

  name        = "my-secure-app-alb"
  environment = "prod"
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]

  load_balancer_type = "application"
  internal           = false

  target_groups = [
    {
      name        = "web"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      vpc_id      = "vpc-12345678"
      health_check_path = "/health"
      stickiness = {
        type            = "lb_cookie"
        cookie_duration = 86400
        enabled         = true
      }
    },
    {
      name        = "api"
      port        = 8080
      protocol    = "HTTP"
      target_type = "instance"
      vpc_id      = "vpc-12345678"
      health_check_path = "/api/health"
    }
  ]

  listeners = [
    {
      port          = 80
      protocol      = "HTTP"
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
    bucket  = "my-lb-logs-bucket"
    prefix  = "alb-logs"
    enabled = true
  }

  waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/my-waf/12345678-1234-1234-1234-123456789012"

  tags = {
    Project     = "my-app"
    Environment = "production"
  }
}
```

### Network Load Balancer

```hcl
module "nlb" {
  source = "./tfm-aws-lb"

  name        = "my-network-lb"
  environment = "prod"
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]

  load_balancer_type = "network"
  internal           = false

  target_groups = [
    {
      name        = "tcp"
      port        = 80
      protocol    = "TCP"
      target_type = "instance"
      vpc_id      = "vpc-12345678"
      health_check_protocol = "TCP"
      health_check_port     = "80"
    }
  ]

  listeners = [
    {
      port     = 80
      protocol = "TCP"
      default_action = {
        type = "forward"
        target_group_arn = null
      }
    }
  ]

  tags = {
    Project     = "my-app"
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access_logs | Access logs configuration | `object({bucket = string, prefix = string, enabled = bool})` | `{bucket = "", prefix = "", enabled = false}` | no |
| cloudwatch_log_group_name | CloudWatch log group name | `string` | `""` | no |
| cloudwatch_log_retention_days | CloudWatch log retention days | `number` | `30` | no |
| enable_cloudwatch_logs | Enable CloudWatch logs | `bool` | `true` | no |
| enable_cross_zone_load_balancing | Enable cross-zone load balancing | `bool` | `true` | no |
| enable_deletion_protection | Enable deletion protection | `bool` | `false` | no |
| enable_http2 | Enable HTTP/2 (ALB only) | `bool` | `true` | no |
| environment | Environment name | `string` | n/a | yes |
| idle_timeout | Connection idle timeout in seconds | `number` | `60` | no |
| internal | Internal or internet-facing | `bool` | `false` | no |
| listeners | Listener configurations | `list(object({...}))` | n/a | yes |
| load_balancer_type | Load balancer type | `string` | `"application"` | no |
| name | Load balancer name | `string` | n/a | yes |
| security_group_ids | Security group IDs | `list(string)` | `[]` | no |
| subnet_ids | Subnet IDs | `list(string)` | n/a | yes |
| tags | Resource tags | `map(string)` | `{}` | no |
| target_groups | Target group configurations | `list(object({...}))` | n/a | yes |
| vpc_id | VPC ID | `string` | n/a | yes |
| waf_web_acl_arn | WAF Web ACL ARN | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudwatch_alarm_arns | CloudWatch alarm ARNs |
| cloudwatch_log_group_arn | CloudWatch log group ARN |
| cloudwatch_log_group_name | CloudWatch log group name |
| listener_arns | Listener ARNs |
| load_balancer_arn | Load balancer ARN |
| load_balancer_arn_suffix | Load balancer ARN suffix |
| load_balancer_dns_name | Load balancer DNS name |
| load_balancer_id | Load balancer ID |
| load_balancer_internal | Internal load balancer flag |
| load_balancer_name | Load balancer name |
| load_balancer_type | Load balancer type |
| load_balancer_zone_id | Load balancer zone ID |
| security_group_arn | Security group ARN |
| security_group_id | Security group ID |
| tags | Resource tags |
| target_group_arns | Target group ARNs |
| target_group_names | Target group names |
| waf_web_acl_association_id | WAF Web ACL association ID |

## Security Features

### Security Groups
The module creates a security group with:
- Ingress: HTTP (80) and HTTPS (443) from anywhere
- Egress: All outbound traffic

### WAF Integration
Associate a WAF Web ACL for additional security:

```hcl
waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/my-waf/12345678-1234-1234-1234-123456789012"
```

### SSL/TLS Termination
Support for SSL/TLS termination with configurable SSL policies and certificate ARNs.

## Monitoring and Logging

### CloudWatch Logs
Automatically creates CloudWatch log groups with configurable retention periods.

### CloudWatch Alarms
Three CloudWatch alarms are created by default:
- Healthy Hosts: Alerts when healthy host count drops below 1
- Unhealthy Hosts: Alerts when unhealthy host count is greater than 0
- Target Response Time: Alerts when response time exceeds 5 seconds

### Access Logs
Support for S3 access logs with configurable bucket and prefix.

## Best Practices

### High Availability
- Use at least 2 subnets in different Availability Zones
- Enable cross-zone load balancing
- Use health checks to ensure traffic only goes to healthy targets

### Security
- Use HTTPS listeners with valid SSL certificates
- Associate WAF Web ACLs for additional protection
- Use security groups to restrict access
- Enable deletion protection for production environments

### Performance
- Use appropriate target types (instance, ip, lambda)
- Configure health check intervals and timeouts appropriately
- Use stickiness when session persistence is required

### Cost Optimization
- Use internal load balancers when external access is not required
- Configure appropriate log retention periods
- Use appropriate instance types for your target groups

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.