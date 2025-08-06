variable "name" {
  description = "Load balancer name - used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "Load balancer name must contain only alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name for resource tagging and naming conventions"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "load_balancer_type" {
  description = "Load balancer type - application for HTTP/HTTPS, network for TCP/UDP"
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network"], var.load_balancer_type)
    error_message = "Load balancer type must be either 'application' or 'network'."
  }
}

variable "internal" {
  description = "Set to true for internal load balancers, false for internet-facing"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the load balancer will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs - minimum 2 for high availability"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets are required for high availability."
  }
}

variable "security_group_ids" {
  description = "Existing security group IDs - if empty, creates a new security group"
  type        = list(string)
  default     = []
}

variable "idle_timeout" {
  description = "Connection idle timeout in seconds (1-4000)"
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "Idle timeout must be between 1 and 4000 seconds."
  }
}

variable "enable_deletion_protection" {
  description = "Prevents accidental deletion of the load balancer"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Distributes traffic across all AZs for better availability"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Enables HTTP/2 protocol support (ALB only)"
  type        = bool
  default     = true
}

# Enhanced Load Balancer Configuration
variable "load_balancer_description" {
  description = "Description for the load balancer"
  type        = string
  default     = "" # Default: empty string
}

variable "load_balancer_tags" {
  description = "Additional tags for the load balancer"
  type        = map(string)
  default     = {} # Default: empty map
}

variable "enable_ipv6" {
  description = "Enable IPv6 support for the load balancer"
  type        = bool
  default     = false # Default: false (IPv4 only)
}

variable "enable_dualstack" {
  description = "Enable dualstack mode for the load balancer"
  type        = bool
  default     = false # Default: false (IPv4 only)
}

variable "customer_owned_ipv4_pool" {
  description = "Customer owned IPv4 pool for the load balancer"
  type        = string
  default     = "" # Default: empty string
}

variable "desync_mitigation_mode" {
  description = "Desync mitigation mode for the load balancer"
  type        = string
  default     = "defensive" # Default: defensive

  validation {
    condition     = contains(["monitor", "defensive", "strictest"], var.desync_mitigation_mode)
    error_message = "Desync mitigation mode must be one of: monitor, defensive, strictest."
  }
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid header fields (ALB only)"
  type        = bool
  default     = false # Default: false (keep invalid headers)
}

variable "preserve_host_header" {
  description = "Preserve host header (ALB only)"
  type        = bool
  default     = false # Default: false (modify host header)
}

variable "x_amzn_tls_version_and_cipher_suite" {
  description = "TLS version and cipher suite headers (ALB only)"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "xff_header_processing_mode" {
  description = "X-Forwarded-For header processing mode (ALB only)"
  type        = string
  default     = "append" # Default: append

  validation {
    condition     = contains(["append", "preserve", "remove"], var.xff_header_processing_mode)
    error_message = "XFF header processing mode must be one of: append, preserve, remove."
  }
}

variable "xff_client_port" {
  description = "Include client port in X-Forwarded-For header (ALB only)"
  type        = bool
  default     = false # Default: false (exclude client port)
}

variable "access_logs" {
  description = "Access logs configuration"
  type = object({
    bucket  = string
    prefix  = string
    enabled = bool
  })
  default = {
    bucket  = "" # Default: empty string
    prefix  = "" # Default: empty string
    enabled = false # Default: false (disabled)
  }
}

# Enhanced Access Logs Configuration
variable "access_logs_bucket" {
  description = "S3 bucket for access logs"
  type        = string
  default     = "" # Default: empty string
}

variable "access_logs_prefix" {
  description = "S3 prefix for access logs"
  type        = string
  default     = "" # Default: empty string
}

variable "access_logs_enabled" {
  description = "Enable access logs"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "allowed_ipv4_cidr_blocks" {
  description = "List of allowed IPv4 CIDR blocks for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition     = alltrue([for cidr in var.allowed_ipv4_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All values must be valid IPv4 CIDR blocks."
  }
}

variable "allowed_ipv6_cidr_blocks" {
  description = "List of allowed IPv6 CIDR blocks for HTTP/HTTPS access"
  type        = list(string)
  default     = ["::/0"]
  
  validation {
    condition     = alltrue([for cidr in var.allowed_ipv6_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All values must be valid IPv6 CIDR blocks."
  }
}

variable "enable_wafv2" {
  description = "Enable WAFv2 integration for the load balancer"
  type        = bool
  default     = false
}

variable "wafv2_web_acl_arn" {
  description = "ARN of the WAFv2 web ACL to associate with the load balancer"
  type        = string
  default     = ""
}

variable "access_logs_tags" {
  description = "Tags for access logs S3 bucket"
  type        = map(string)
  default     = {} # Default: empty map
}

variable "target_groups" {
  description = "List of target group configurations"
  type = list(object({
    name                 = string
    port                 = number
    protocol             = string
    target_type          = string
    vpc_id               = string
    health_check_path    = optional(string, "/") # Default: "/"
    health_check_port    = optional(string, "traffic-port") # Default: "traffic-port"
    health_check_protocol = optional(string, "HTTP") # Default: "HTTP"
    health_check_interval = optional(number, 30) # Default: 30 seconds
    health_check_timeout  = optional(number, 5) # Default: 5 seconds
    healthy_threshold     = optional(number, 2) # Default: 2
    unhealthy_threshold   = optional(number, 2) # Default: 2
    matcher               = optional(string, "200") # Default: "200"
    deregistration_delay  = optional(number, 300) # Default: 300 seconds
    stickiness = optional(object({
      type            = string
      cookie_duration = number
      enabled         = bool
    }), null) # Default: null (disabled)
  }))

  validation {
    condition = alltrue([
      for tg in var.target_groups : contains(["instance", "ip", "lambda", "alb"], tg.target_type)
    ])
    error_message = "Target type must be one of: instance, ip, lambda, alb."
  }
}

# Enhanced Target Group Configuration
variable "target_group_description" {
  description = "Description for target groups"
  type        = string
  default     = "" # Default: empty string
}

variable "target_group_tags" {
  description = "Additional tags for target groups"
  type        = map(string)
  default     = {} # Default: empty map
}

variable "target_group_health_check_enabled" {
  description = "Enable health checks for target groups"
  type        = bool
  default     = true # Default: true (enabled)
}

variable "target_group_health_check_success_codes" {
  description = "Success codes for health checks"
  type        = string
  default     = "200" # Default: "200"
}

variable "target_group_health_check_grace_period" {
  description = "Grace period for health checks (seconds)"
  type        = number
  default     = 0 # Default: 0 seconds
}

variable "target_group_health_check_healthy_threshold_count" {
  description = "Number of consecutive health check successes required"
  type        = number
  default     = 2 # Default: 2
}

variable "target_group_health_check_unhealthy_threshold_count" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 2 # Default: 2
}

variable "target_group_health_check_interval_seconds" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30 # Default: 30 seconds
}

variable "target_group_health_check_timeout_seconds" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5 # Default: 5 seconds
}

variable "target_group_health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/" # Default: "/"
}

variable "target_group_health_check_port" {
  description = "Health check port"
  type        = string
  default     = "traffic-port" # Default: "traffic-port"
}

variable "target_group_health_check_protocol" {
  description = "Health check protocol"
  type        = string
  default     = "HTTP" # Default: "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP"], var.target_group_health_check_protocol)
    error_message = "Health check protocol must be one of: HTTP, HTTPS, TCP, TLS, UDP, TCP_UDP."
  }
}

variable "target_group_stickiness_enabled" {
  description = "Enable stickiness for target groups"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "target_group_stickiness_type" {
  description = "Stickiness type for target groups"
  type        = string
  default     = "lb_cookie" # Default: "lb_cookie"

  validation {
    condition     = contains(["lb_cookie", "app_cookie"], var.target_group_stickiness_type)
    error_message = "Stickiness type must be one of: lb_cookie, app_cookie."
  }
}

variable "target_group_stickiness_cookie_duration" {
  description = "Stickiness cookie duration in seconds"
  type        = number
  default     = 86400 # Default: 86400 seconds (24 hours)
}

variable "target_group_stickiness_cookie_name" {
  description = "Stickiness cookie name (for app_cookie type)"
  type        = string
  default     = "" # Default: empty string
}

variable "target_group_deregistration_delay" {
  description = "Deregistration delay in seconds"
  type        = number
  default     = 300 # Default: 300 seconds
}

variable "target_group_lambda_multi_value_headers_enabled" {
  description = "Enable multi-value headers for Lambda targets"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "target_group_proxy_protocol_v2" {
  description = "Enable proxy protocol v2"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "target_group_load_balancing_algorithm_type" {
  description = "Load balancing algorithm type"
  type        = string
  default     = "round_robin" # Default: "round_robin"

  validation {
    condition     = contains(["round_robin", "least_outstanding_requests"], var.target_group_load_balancing_algorithm_type)
    error_message = "Load balancing algorithm type must be one of: round_robin, least_outstanding_requests."
  }
}

variable "target_group_slow_start" {
  description = "Slow start duration in seconds"
  type        = number
  default     = 0 # Default: 0 seconds (disabled)
}

variable "listeners" {
  description = "List of listener configurations"
  type = list(object({
    port     = number
    protocol = string
    ssl_policy = optional(string) # Default: null
    certificate_arn = optional(string) # Default: null
    default_action = object({
      type             = string
      target_group_arn = optional(string) # Default: null
      fixed_response = optional(object({
        content_type = string
        message_body = string
        status_code  = string
      })) # Default: null
      redirect = optional(object({
        path        = string
        host        = string
        port        = string
        protocol    = string
        query       = string
        status_code = string
      })) # Default: null
    })
    rules = optional(list(object({
      priority = number
      action = object({
        type             = string
        target_group_arn = optional(string) # Default: null
        fixed_response = optional(object({
          content_type = string
          message_body = string
          status_code  = string
        })) # Default: null
        redirect = optional(object({
          path        = string
          host        = string
          port        = string
          protocol    = string
          query       = string
          status_code = string
        })) # Default: null
      })
      condition = object({
        field  = string
        values = list(string)
      })
    })), []) # Default: empty list
  }))
}

# Enhanced Listener Configuration
variable "listener_description" {
  description = "Description for listeners"
  type        = string
  default     = "" # Default: empty string
}

variable "listener_tags" {
  description = "Additional tags for listeners"
  type        = map(string)
  default     = {} # Default: empty map
}

variable "listener_ssl_policy" {
  description = "SSL policy for HTTPS listeners"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01" # Default: ELBSecurityPolicy-TLS-1-2-2017-01
}

variable "listener_certificate_arn" {
  description = "Certificate ARN for HTTPS listeners"
  type        = string
  default     = "" # Default: empty string
}

variable "listener_alpn_policy" {
  description = "ALPN policy for listeners"
  type        = string
  default     = "" # Default: empty string

  validation {
    condition     = var.listener_alpn_policy == "" || contains(["HTTP1Only", "HTTP2Only", "HTTP2Optional", "HTTP2Preferred", "None"], var.listener_alpn_policy)
    error_message = "ALPN policy must be one of: HTTP1Only, HTTP2Only, HTTP2Optional, HTTP2Preferred, None."
  }
}

variable "listener_mutual_authentication" {
  description = "Mutual authentication configuration for listeners"
  type = object({
    mode                   = string
    trust_store_arn        = string
    ignore_client_certificate_expiry = bool
  })
  default = {
    mode                   = "off" # Default: off
    trust_store_arn        = "" # Default: empty string
    ignore_client_certificate_expiry = false # Default: false
  }
}

variable "listener_default_action_type" {
  description = "Default action type for listeners"
  type        = string
  default     = "forward" # Default: forward

  validation {
    condition     = contains(["forward", "redirect", "fixed-response", "authenticate-cognito", "authenticate-oidc"], var.listener_default_action_type)
    error_message = "Default action type must be one of: forward, redirect, fixed-response, authenticate-cognito, authenticate-oidc."
  }
}

variable "listener_fixed_response_content_type" {
  description = "Content type for fixed response actions"
  type        = string
  default     = "text/plain" # Default: text/plain
}

variable "listener_fixed_response_message_body" {
  description = "Message body for fixed response actions"
  type        = string
  default     = "" # Default: empty string
}

variable "listener_fixed_response_status_code" {
  description = "Status code for fixed response actions"
  type        = string
  default     = "200" # Default: 200
}

variable "listener_redirect_path" {
  description = "Redirect path for redirect actions"
  type        = string
  default     = "/" # Default: "/"
}

variable "listener_redirect_host" {
  description = "Redirect host for redirect actions"
  type        = string
  default     = "#{host}" # Default: "#{host}"
}

variable "listener_redirect_port" {
  description = "Redirect port for redirect actions"
  type        = string
  default     = "#{port}" # Default: "#{port}"
}

variable "listener_redirect_protocol" {
  description = "Redirect protocol for redirect actions"
  type        = string
  default     = "#{protocol}" # Default: "#{protocol}"
}

variable "listener_redirect_query" {
  description = "Redirect query for redirect actions"
  type        = string
  default     = "#{query}" # Default: "#{query}"
}

variable "listener_redirect_status_code" {
  description = "Redirect status code for redirect actions"
  type        = string
  default     = "HTTP_301" # Default: HTTP_301

  validation {
    condition     = contains(["HTTP_301", "HTTP_302"], var.listener_redirect_status_code)
    error_message = "Redirect status code must be one of: HTTP_301, HTTP_302."
  }
}

variable "tags" {
  description = "A map of tags to assign to the load balancer"
  type        = map(string)
  default     = {} # Default: empty map
}

# Enhanced Security Group Configuration
variable "security_group_description" {
  description = "Description for the security group"
  type        = string
  default     = "Security group for load balancer" # Default: "Security group for load balancer"
}

variable "security_group_tags" {
  description = "Additional tags for the security group"
  type        = map(string)
  default     = {} # Default: empty map
}

variable "security_group_ingress_rules" {
  description = "Additional ingress rules for the security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    security_groups = list(string)
    self = bool
  }))
  default = [] # Default: empty list
}

variable "security_group_egress_rules" {
  description = "Additional egress rules for the security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    security_groups = list(string)
    self = bool
  }))
  default = [] # Default: empty list
}

variable "security_group_create_before_destroy" {
  description = "Create security group before destroying"
  type        = bool
  default     = true # Default: true
}

# Enhanced WAF Configuration
variable "waf_web_acl_arn" {
  description = "ARN of WAF Web ACL to associate with the load balancer"
  type        = string
  default     = "" # Default: empty string
}

variable "waf_association_tags" {
  description = "Additional tags for WAF association"
  type        = map(string)
  default     = {} # Default: empty map
}

# Enhanced CloudWatch Configuration
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for the load balancer"
  type        = bool
  default     = true # Default: true (enabled)
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = "" # Default: empty string
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30 # Default: 30 days

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention days must be one of the allowed values."
  }
}

variable "cloudwatch_log_group_tags" {
  description = "Additional tags for CloudWatch log group"
  type        = map(string)
  default     = {} # Default: empty map
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = "" # Default: empty string
}

# Enhanced CloudWatch Alarms Configuration
variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for the load balancer"
  type        = bool
  default     = true # Default: true (enabled)
}

variable "cloudwatch_alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms"
  type        = number
  default     = 2 # Default: 2
}

variable "cloudwatch_alarm_period" {
  description = "Period in seconds for CloudWatch alarms"
  type        = number
  default     = 300 # Default: 300 seconds (5 minutes)
}

variable "cloudwatch_alarm_threshold" {
  description = "Threshold for CloudWatch alarms"
  type        = number
  default     = 1 # Default: 1
}

variable "cloudwatch_alarm_comparison_operator" {
  description = "Comparison operator for CloudWatch alarms"
  type        = string
  default     = "LessThanThreshold" # Default: LessThanThreshold

  validation {
    condition     = contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"], var.cloudwatch_alarm_comparison_operator)
    error_message = "Comparison operator must be one of: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold."
  }
}

variable "cloudwatch_alarm_statistic" {
  description = "Statistic for CloudWatch alarms"
  type        = string
  default     = "Average" # Default: Average

  validation {
    condition     = contains(["SampleCount", "Average", "Sum", "Minimum", "Maximum"], var.cloudwatch_alarm_statistic)
    error_message = "Statistic must be one of: SampleCount, Average, Sum, Minimum, Maximum."
  }
}

variable "cloudwatch_alarm_treat_missing_data" {
  description = "How to treat missing data in CloudWatch alarms"
  type        = string
  default     = "missing" # Default: missing

  validation {
    condition     = contains(["breaching", "notBreaching", "ignore", "missing"], var.cloudwatch_alarm_treat_missing_data)
    error_message = "Treat missing data must be one of: breaching, notBreaching, ignore, missing."
  }
}

variable "cloudwatch_alarm_actions" {
  description = "Actions to take when CloudWatch alarms are triggered"
  type        = list(string)
  default     = [] # Default: empty list
}

variable "cloudwatch_alarm_ok_actions" {
  description = "Actions to take when CloudWatch alarms return to OK state"
  type        = list(string)
  default     = [] # Default: empty list
}

variable "cloudwatch_alarm_insufficient_data_actions" {
  description = "Actions to take when CloudWatch alarms have insufficient data"
  type        = list(string)
  default     = [] # Default: empty list
}

variable "cloudwatch_alarm_tags" {
  description = "Additional tags for CloudWatch alarms"
  type        = map(string)
  default     = {} # Default: empty map
}

# Custom CloudWatch Alarms
variable "custom_cloudwatch_alarms" {
  description = "Custom CloudWatch alarms configuration"
  type = map(object({
    alarm_name          = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_description   = string
    alarm_actions       = list(string)
    ok_actions          = list(string)
    insufficient_data_actions = list(string)
    treat_missing_data  = string
    unit                = string
    extended_statistic  = string
    datapoints_to_alarm = number
    threshold_metric_id = string
    dimensions = map(string)
    metric_query = list(object({
      id          = string
      expression  = string
      label       = string
      return_data = bool
      metric = object({
        metric_name = string
        namespace   = string
        period      = number
        stat        = string
        unit        = string
        dimensions  = map(string)
      })
    }))
  }))
  default = {} # Default: empty map
}

# Enhanced Monitoring and Observability
variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring features"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "enable_request_tracing" {
  description = "Enable request tracing for debugging"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "enable_performance_insights" {
  description = "Enable performance insights"
  type        = bool
  default     = false # Default: false (disabled)
}

# Enhanced Security Features
variable "enable_shield_advanced" {
  description = "Enable AWS Shield Advanced protection"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "enable_guardduty_integration" {
  description = "Enable AWS GuardDuty integration"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "enable_security_hub_integration" {
  description = "Enable AWS Security Hub integration"
  type        = bool
  default     = false # Default: false (disabled)
}

# Enhanced Cost Optimization
variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for target groups"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "auto_scaling_config" {
  description = "Auto scaling configuration"
  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
    target_cpu_utilization = number
    target_memory_utilization = number
    scale_up_cooldown   = number
    scale_down_cooldown = number
  })
  default = {
    min_size         = 1 # Default: 1
    max_size         = 10 # Default: 10
    desired_capacity = 2 # Default: 2
    target_cpu_utilization = 70 # Default: 70%
    target_memory_utilization = 80 # Default: 80%
    scale_up_cooldown   = 300 # Default: 300 seconds
    scale_down_cooldown = 300 # Default: 300 seconds
  }
}

# Enhanced Compliance and Governance
variable "enable_compliance_tagging" {
  description = "Enable compliance tagging"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "compliance_tags" {
  description = "Compliance tags to apply to all resources"
  type = object({
    data_classification = string
    business_unit       = string
    cost_center         = string
    owner               = string
    backup_required     = string
    encryption_required = string
  })
  default = {
    data_classification = "internal" # Default: internal
    business_unit       = "it" # Default: it
    cost_center         = "cc-001" # Default: cc-001
    owner               = "terraform" # Default: terraform
    backup_required     = "false" # Default: false
    encryption_required = "true" # Default: true
  }
}

variable "enable_resource_policies" {
  description = "Enable resource policies"
  type        = bool
  default     = false # Default: false (disabled)
}

variable "resource_policies" {
  description = "Resource policies configuration"
  type = map(object({
    policy_document = string
    policy_name     = string
    policy_type     = string
  }))
  default = {} # Default: empty map
} 