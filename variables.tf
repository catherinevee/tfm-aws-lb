variable "name" {
  description = "Name of the load balancer"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "Load balancer name must contain only alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "load_balancer_type" {
  description = "Type of load balancer (application or network)"
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network"], var.load_balancer_type)
    error_message = "Load balancer type must be either 'application' or 'network'."
  }
}

variable "internal" {
  description = "Whether the load balancer is internal or internet-facing"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the load balancer will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets are required for high availability."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the load balancer"
  type        = list(string)
  default     = []
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "Idle timeout must be between 1 and 4000 seconds."
  }
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing will be enabled"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "If true, HTTP/2 will be enabled (ALB only)"
  type        = bool
  default     = true
}

variable "access_logs" {
  description = "Access logs configuration"
  type = object({
    bucket  = string
    prefix  = string
    enabled = bool
  })
  default = {
    bucket  = ""
    prefix  = ""
    enabled = false
  }
}

variable "target_groups" {
  description = "List of target group configurations"
  type = list(object({
    name                 = string
    port                 = number
    protocol             = string
    target_type          = string
    vpc_id               = string
    health_check_path    = optional(string, "/")
    health_check_port    = optional(string, "traffic-port")
    health_check_protocol = optional(string, "HTTP")
    health_check_interval = optional(number, 30)
    health_check_timeout  = optional(number, 5)
    healthy_threshold     = optional(number, 2)
    unhealthy_threshold   = optional(number, 2)
    matcher               = optional(string, "200")
    deregistration_delay  = optional(number, 300)
    stickiness = optional(object({
      type            = string
      cookie_duration = number
      enabled         = bool
    }), null)
  }))

  validation {
    condition = alltrue([
      for tg in var.target_groups : contains(["instance", "ip", "lambda", "alb"], tg.target_type)
    ])
    error_message = "Target type must be one of: instance, ip, lambda, alb."
  }
}

variable "listeners" {
  description = "List of listener configurations"
  type = list(object({
    port     = number
    protocol = string
    ssl_policy = optional(string)
    certificate_arn = optional(string)
    default_action = object({
      type             = string
      target_group_arn = optional(string)
      fixed_response = optional(object({
        content_type = string
        message_body = string
        status_code  = string
      }))
      redirect = optional(object({
        path        = string
        host        = string
        port        = string
        protocol    = string
        query       = string
        status_code = string
      }))
    })
    rules = optional(list(object({
      priority = number
      action = object({
        type             = string
        target_group_arn = optional(string)
        fixed_response = optional(object({
          content_type = string
          message_body = string
          status_code  = string
        }))
        redirect = optional(object({
          path        = string
          host        = string
          port        = string
          protocol    = string
          query       = string
          status_code = string
        }))
      })
      condition = object({
        field  = string
        values = list(string)
      })
    })), [])
  }))
}

variable "tags" {
  description = "A map of tags to assign to the load balancer"
  type        = map(string)
  default     = {}
}

variable "waf_web_acl_arn" {
  description = "ARN of WAF Web ACL to associate with the load balancer"
  type        = string
  default     = ""
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for the load balancer"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = ""
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention days must be one of the allowed values."
  }
} 