# AWS Load Balancer Terraform Module

A comprehensive Terraform module for creating AWS Application Load Balancers (ALB) and Network Load Balancers (NLB) with advanced features for high availability, scalability, and security.

## Features

- **Multi-Type Support**: Application Load Balancer (ALB) and Network Load Balancer (NLB)
- **High Availability**: Cross-zone load balancing and multi-AZ deployment
- **Security**: Built-in security groups, WAF integration, and SSL/TLS termination
- **Monitoring**: CloudWatch logs, metrics, and alarms
- **Flexibility**: Support for multiple target groups, listeners, and routing rules
- **Compliance**: Comprehensive tagging and resource management

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.lb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.lb_healthy_hosts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lb_target_response_time](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lb_unhealthy_hosts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_lb.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_wafv2_web_acl_association.lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs"></a> [access_logs](#input_access_logs) | Access logs configuration | `object({bucket = string, prefix = string, enabled = bool})` | `{bucket = "", prefix = "", enabled = false}` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch_log_group_name](#input_cloudwatch_log_group_name) | Name of the CloudWatch log group | `string` | `""` | no |
| <a name="input_cloudwatch_log_retention_days"></a> [cloudwatch_log_retention_days](#input_cloudwatch_log_retention_days) | Number of days to retain CloudWatch logs | `number` | `30` | no |
| <a name="input_enable_cloudwatch_logs"></a> [enable_cloudwatch_logs](#input_enable_cloudwatch_logs) | Enable CloudWatch logs for the load balancer | `bool` | `true` | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable_cross_zone_load_balancing](#input_enable_cross_zone_load_balancing) | If true, cross-zone load balancing will be enabled | `bool` | `true` | no |
| <a name="input_enable_deletion_protection"></a> [enable_deletion_protection](#input_enable_deletion_protection) | If true, deletion of the load balancer will be disabled | `bool` | `false` | no |
| <a name="input_enable_http2"></a> [enable_http2](#input_enable_http2) | If true, HTTP/2 will be enabled (ALB only) | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input_environment) | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| <a name="input_idle_timeout"></a> [idle_timeout](#input_idle_timeout) | The time in seconds that the connection is allowed to be idle | `number` | `60` | no |
| <a name="input_internal"></a> [internal](#input_internal) | Whether the load balancer is internal or internet-facing | `bool` | `false` | no |
| <a name="input_listeners"></a> [listeners](#input_listeners) | List of listener configurations | `list(object({port = number, protocol = string, ssl_policy = optional(string), certificate_arn = optional(string), default_action = object({type = string, target_group_arn = optional(string), fixed_response = optional(object({content_type = string, message_body = string, status_code = string})), redirect = optional(object({path = string, host = string, port = string, protocol = string, query = string, status_code = string}))}), rules = optional(list(object({priority = number, action = object({type = string, target_group_arn = optional(string), fixed_response = optional(object({content_type = string, message_body = string, status_code = string})), redirect = optional(object({path = string, host = string, port = string, protocol = string, query = string, status_code = string}))}), condition = object({field = string, values = list(string)}))}), []))` | n/a | yes |
| <a name="input_load_balancer_type"></a> [load_balancer_type](#input_load_balancer_type) | Type of load balancer (application or network) | `string` | `"application"` | no |
| <a name="input_name"></a> [name](#input_name) | Name of the load balancer | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security_group_ids](#input_security_group_ids) | List of security group IDs to attach to the load balancer | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids) | List of subnet IDs for the load balancer | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input_tags) | A map of tags to assign to the load balancer | `map(string)` | `{}` | no |
| <a name="input_target_groups"></a> [target_groups](#input_target_groups) | List of target group configurations | `list(object({name = string, port = number, protocol = string, target_type = string, vpc_id = string, health_check_path = optional(string), health_check_port = optional(string), health_check_protocol = optional(string), health_check_interval = optional(number), health_check_timeout = optional(number), healthy_threshold = optional(number), unhealthy_threshold = optional(number), matcher = optional(string), deregistration_delay = optional(number), stickiness = optional(object({type = string, cookie_duration = number, enabled = bool})), null}))` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | VPC ID where the load balancer will be created | `string` | n/a | yes |
| <a name="input_waf_web_acl_arn"></a> [waf_web_acl_arn](#input_waf_web_acl_arn) | ARN of WAF Web ACL to associate with the load balancer | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_alarm_arns"></a> [cloudwatch_alarm_arns](#output_cloudwatch_alarm_arns) | Map of CloudWatch alarm names to ARNs |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch_log_group_arn](#output_cloudwatch_log_group_arn) | The ARN of the CloudWatch log group |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch_log_group_name](#output_cloudwatch_log_group_name) | The name of the CloudWatch log group |
| <a name="output_listener_arns"></a> [listener_arns](#output_listener_arns) | Map of listener port-protocol to ARNs |
| <a name="output_load_balancer_arn"></a> [load_balancer_arn](#output_load_balancer_arn) | The ARN of the load balancer |
| <a name="output_load_balancer_arn_suffix"></a> [load_balancer_arn_suffix](#output_load_balancer_arn_suffix) | The ARN suffix of the load balancer |
| <a name="output_load_balancer_dns_name"></a> [load_balancer_dns_name](#output_load_balancer_dns_name) | The DNS name of the load balancer |
| <a name="output_load_balancer_id"></a> [load_balancer_id](#output_load_balancer_id) | The ID of the load balancer |
| <a name="output_load_balancer_internal"></a> [load_balancer_internal](#output_load_balancer_internal) | Whether the load balancer is internal |
| <a name="output_load_balancer_name"></a> [load_balancer_name](#output_load_balancer_name) | The name of the load balancer |
| <a name="output_load_balancer_type"></a> [load_balancer_type](#output_load_balancer_type) | The type of load balancer |
| <a name="output_load_balancer_zone_id"></a> [load_balancer_zone_id](#output_load_balancer_zone_id) | The canonical hosted zone ID of the load balancer |
| <a name="output_security_group_arn"></a> [security_group_arn](#output_security_group_arn) | The ARN of the security group created for the load balancer |
| <a name="output_security_group_id"></a> [security_group_id](#output_security_group_id) | The ID of the security group created for the load balancer |
| <a name="output_tags"></a> [tags](#output_tags) | A map of tags assigned to the load balancer |
| <a name="output_target_group_arns"></a> [target_group_arns](#output_target_group_arns) | Map of target group names to ARNs |
| <a name="output_target_group_names"></a> [target_group_names](#output_target_group_names) | Map of target group names to full names |
| <a name="output_waf_web_acl_association_id"></a> [waf_web_acl_association_id](#output_waf_web_acl_association_id) | The ID of the WAF Web ACL association |

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
        target_group_arn = null  # Will use first target group
      }
    }
  ]

  tags = {
    Project     = "my-app"
    Environment = "production"
  }
}
```

### Advanced Load Balancer with SSL/TLS

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
            target_group_arn = null  # Will use first target group
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

## Security Features

### Security Groups
The module creates a security group with the following rules:
- **Ingress**: HTTP (80) and HTTPS (443) from anywhere
- **Egress**: All outbound traffic

### WAF Integration
You can associate a WAF Web ACL with the load balancer for additional security:

```hcl
waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/my-waf/12345678-1234-1234-1234-123456789012"
```

### SSL/TLS Termination
Support for SSL/TLS termination with configurable SSL policies and certificate ARNs.

## Monitoring and Logging

### CloudWatch Logs
The module automatically creates CloudWatch log groups for load balancer logs with configurable retention periods.

### CloudWatch Alarms
Three CloudWatch alarms are created by default:
- **Healthy Hosts**: Alerts when healthy host count drops below 1
- **Unhealthy Hosts**: Alerts when unhealthy host count is greater than 0
- **Target Response Time**: Alerts when response time exceeds 5 seconds

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

This module is licensed under the MIT License. See LICENSE file for details.