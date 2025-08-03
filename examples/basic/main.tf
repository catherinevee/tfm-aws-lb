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

# Enhanced Application Load Balancer
module "alb_enhanced" {
  source = "../../"

  name        = "enhanced-alb-example"
  environment = "dev"
  vpc_id      = data.aws_vpc.default.id
  subnet_ids  = slice(data.aws_subnets.default.ids, 0, 2)

  # Enhanced Load Balancer Configuration
  load_balancer_type = "application"
  internal           = false
  load_balancer_description = "Enhanced ALB with comprehensive features"
  idle_timeout       = 120
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
  enable_http2       = true
  desync_mitigation_mode = "defensive"
  drop_invalid_header_fields = true
  preserve_host_header = false
  x_amzn_tls_version_and_cipher_suite = true
  xff_header_processing_mode = "append"
  xff_client_port = false

  # Enhanced Target Groups
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
    }
  ]

  # Enhanced Target Group Configuration
  target_group_description = "Web application target group"
  target_group_health_check_enabled = true
  target_group_health_check_success_codes = "200,302"
  target_group_health_check_grace_period = 60
  target_group_health_check_healthy_threshold_count = 3
  target_group_health_check_unhealthy_threshold_count = 3
  target_group_health_check_interval_seconds = 30
  target_group_health_check_timeout_seconds = 5
  target_group_health_check_path = "/health"
  target_group_health_check_port = "traffic-port"
  target_group_health_check_protocol = "HTTP"
  target_group_stickiness_enabled = true
  target_group_stickiness_type = "lb_cookie"
  target_group_stickiness_cookie_duration = 86400
  target_group_stickiness_cookie_name = "session"
  target_group_deregistration_delay = 300
  target_group_lambda_multi_value_headers_enabled = false
  target_group_proxy_protocol_v2 = false
  target_group_load_balancing_algorithm_type = "round_robin"
  target_group_slow_start = 0

  # Enhanced Listeners
  listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "forward"
        target_group_arn = null
      }
    },
    {
      port     = 443
      protocol = "HTTPS"
      ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/example"
      default_action = {
        type = "forward"
        target_group_arn = null
      }
    }
  ]

  # Enhanced Listener Configuration
  listener_description = "Enhanced listener configuration"
  listener_ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  listener_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/example"
  listener_alpn_policy = "HTTP2Preferred"
  listener_mutual_authentication = {
    mode                   = "off"
    trust_store_arn        = ""
    ignore_client_certificate_expiry = false
  }
  listener_default_action_type = "forward"
  listener_fixed_response_content_type = "text/plain"
  listener_fixed_response_message_body = "Service temporarily unavailable"
  listener_fixed_response_status_code = "503"
  listener_redirect_path = "/"
  listener_redirect_host = "#{host}"
  listener_redirect_port = "#{port}"
  listener_redirect_protocol = "#{protocol}"
  listener_redirect_query = "#{query}"
  listener_redirect_status_code = "HTTP_301"

  # Enhanced Security Group Configuration
  security_group_description = "Enhanced security group for ALB"
  security_group_ingress_rules = [
    {
      description = "Custom HTTPS from specific CIDR"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      security_groups = []
      self = false
    }
  ]
  security_group_egress_rules = [
    {
      description = "Custom egress rule"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      security_groups = []
      self = false
    }
  ]
  security_group_create_before_destroy = true

  # Enhanced Access Logs
  access_logs_enabled = true
  access_logs_bucket = "my-alb-logs-bucket"
  access_logs_prefix = "alb-logs"
  access_logs_tags = {
    LogType = "access"
    Retention = "30days"
  }

  # Enhanced CloudWatch Configuration
  enable_cloudwatch_logs = true
  cloudwatch_log_group_name = "/aws/loadbalancer/enhanced-alb"
  cloudwatch_log_retention_days = 30
  cloudwatch_log_group_tags = {
    LogType = "application"
    Retention = "30days"
  }
  cloudwatch_log_group_kms_key_id = ""

  # Enhanced CloudWatch Alarms
  enable_cloudwatch_alarms = true
  cloudwatch_alarm_evaluation_periods = 2
  cloudwatch_alarm_period = 300
  cloudwatch_alarm_threshold = 1
  cloudwatch_alarm_comparison_operator = "LessThanThreshold"
  cloudwatch_alarm_statistic = "Average"
  cloudwatch_alarm_treat_missing_data = "missing"
  cloudwatch_alarm_actions = []
  cloudwatch_alarm_ok_actions = []
  cloudwatch_alarm_insufficient_data_actions = []
  cloudwatch_alarm_tags = {
    AlarmType = "health"
    Severity = "medium"
  }

  # Custom CloudWatch Alarms
  custom_cloudwatch_alarms = {
    high_response_time = {
      alarm_name          = "high-response-time"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "TargetResponseTime"
      namespace           = "AWS/ApplicationELB"
      period              = 300
      statistic           = "Average"
      threshold           = 2.0
      alarm_description   = "High response time alarm"
      alarm_actions       = []
      ok_actions          = []
      insufficient_data_actions = []
      treat_missing_data  = "missing"
      unit                = "Seconds"
      extended_statistic  = ""
      datapoints_to_alarm = 2
      threshold_metric_id = ""
      dimensions = {
        LoadBalancer = "enhanced-alb-example"
      }
      metric_query = []
    }
  }

  # Enhanced WAF Configuration
  waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/example"
  waf_association_tags = {
    WAFType = "regional"
    Protection = "standard"
  }

  # Enhanced Monitoring and Observability
  enable_enhanced_monitoring = true
  enable_request_tracing = true
  enable_performance_insights = false

  # Enhanced Security Features
  enable_shield_advanced = false
  enable_guardduty_integration = true
  enable_security_hub_integration = true

  # Enhanced Cost Optimization
  enable_cost_optimization = true
  enable_auto_scaling = false
  auto_scaling_config = {
    min_size         = 1
    max_size         = 10
    desired_capacity = 2
    target_cpu_utilization = 70
    target_memory_utilization = 80
    scale_up_cooldown   = 300
    scale_down_cooldown = 300
  }

  # Enhanced Compliance and Governance
  enable_compliance_tagging = true
  compliance_tags = {
    data_classification = "internal"
    business_unit       = "engineering"
    cost_center         = "cc-eng-001"
    owner               = "devops-team"
    backup_required     = "false"
    encryption_required = "true"
  }

  enable_resource_policies = false
  resource_policies = {}

  # Enhanced Tags
  tags = {
    Project     = "enhanced-load-balancer"
    Environment = "development"
    Owner       = "devops-team"
    CostCenter  = "cc-eng-001"
    DataClassification = "internal"
    BackupRequired = "false"
    EncryptionRequired = "true"
  }
} 