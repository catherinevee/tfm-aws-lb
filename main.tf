locals {
  # Standard tags applied to all resources
  common_tags = merge(var.tags, {
    Name        = var.name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "tfm-aws-lb"
  })

  # Compliance tags for enterprise environments
  enhanced_tags = var.enable_compliance_tagging ? merge(local.common_tags, {
    DataClassification = var.compliance_tags.data_classification
    BusinessUnit       = var.compliance_tags.business_unit
    CostCenter         = var.compliance_tags.cost_center
    Owner              = var.compliance_tags.owner
    BackupRequired     = var.compliance_tags.backup_required
    EncryptionRequired = var.compliance_tags.encryption_required
  }) : local.common_tags

  # CloudWatch log group name - uses custom name or generates from load balancer name
  log_group_name = var.cloudwatch_log_group_name != "" ? var.cloudwatch_log_group_name : "/aws/loadbalancer/${var.name}"

  # Security group naming convention
  security_group_name = "${var.name}-lb-sg"

  # Load balancer name with optional description suffix
  lb_name = var.load_balancer_description != "" ? "${var.name}-${var.load_balancer_description}" : var.name
}

# CloudWatch log group for load balancer access logs
resource "aws_cloudwatch_log_group" "lb_logs" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = local.log_group_name
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id != "" ? var.cloudwatch_log_group_kms_key_id : null

  tags = merge(local.enhanced_tags, var.cloudwatch_log_group_tags)
}

# Security group for load balancer - only created if no existing security groups provided
resource "aws_security_group" "lb" {
  count       = length(var.security_group_ids) == 0 ? 1 : 0
  name        = local.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id

  # HTTP ingress for ALB only
  dynamic "ingress" {
    for_each = var.load_balancer_type == "application" ? [1] : []
    content {
      description      = "HTTP from allowed IPv4 CIDR blocks"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = var.allowed_ipv4_cidr_blocks
      ipv6_cidr_blocks = var.enable_ipv6 ? var.allowed_ipv6_cidr_blocks : null
    }
  }

  # HTTPS ingress for ALB only
  dynamic "ingress" {
    for_each = var.load_balancer_type == "application" ? [1] : []
    content {
      description      = "HTTPS from allowed IPv4 CIDR blocks"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = var.allowed_ipv4_cidr_blocks
      ipv6_cidr_blocks = var.enable_ipv6 ? var.allowed_ipv6_cidr_blocks : null
    }
  }

  # Custom ingress rules
  dynamic "ingress" {
    for_each = var.security_group_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      security_groups = ingress.value.security_groups
      self = ingress.value.self
    }
  }

  # Default egress - allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom egress rules
  dynamic "egress" {
    for_each = var.security_group_egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      security_groups = egress.value.security_groups
      self = egress.value.self
    }
  }

  tags = merge(local.enhanced_tags, var.security_group_tags)

  lifecycle {
    create_before_destroy = var.security_group_create_before_destroy
  }
}

# Main load balancer resource
resource "aws_lb" "main" {
  name               = local.lb_name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.lb[0].id]
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.load_balancer_type == "application" ? var.enable_http2 : null
  idle_timeout                     = var.idle_timeout

  # Advanced load balancer settings
  customer_owned_ipv4_pool = var.customer_owned_ipv4_pool != "" ? var.customer_owned_ipv4_pool : null
  desync_mitigation_mode   = var.desync_mitigation_mode

  # S3 access logs configuration
  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [1] : []
    content {
      bucket  = var.access_logs.bucket
      prefix  = var.access_logs.prefix
      enabled = true
    }
  }

  # Legacy access logs configuration for backward compatibility
  dynamic "access_logs" {
    for_each = var.access_logs_enabled ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(local.enhanced_tags, var.load_balancer_tags)

  depends_on = [aws_cloudwatch_log_group.lb_logs]
}

# Target groups for routing traffic to backend services
resource "aws_lb_target_group" "main" {
  for_each = { for tg in var.target_groups : tg.name => tg }

  name        = "${var.name}-${each.value.name}"
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = each.value.vpc_id

  # Advanced target group settings
  lambda_multi_value_headers_enabled = var.target_group_lambda_multi_value_headers_enabled
  proxy_protocol_v2                  = var.target_group_proxy_protocol_v2
  load_balancing_algorithm_type      = var.target_group_load_balancing_algorithm_type
  slow_start                         = var.target_group_slow_start

  health_check {
    enabled             = var.target_group_health_check_enabled
    healthy_threshold   = each.value.healthy_threshold
    interval            = each.value.health_check_interval
    matcher             = each.value.matcher
    path                = each.value.health_check_path
    port                = each.value.health_check_port
    protocol            = each.value.health_check_protocol
    timeout             = each.value.health_check_timeout
    unhealthy_threshold = each.value.unhealthy_threshold
  }

  # Session stickiness configuration
  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      enabled         = stickiness.value.enabled
      cookie_name     = var.target_group_stickiness_cookie_name != "" ? var.target_group_stickiness_cookie_name : null
    }
  }

  # Global stickiness settings when not specified per target group
  dynamic "stickiness" {
    for_each = var.target_group_stickiness_enabled && each.value.stickiness == null ? [1] : []
    content {
      type            = var.target_group_stickiness_type
      cookie_duration = var.target_group_stickiness_cookie_duration
      enabled         = true
      cookie_name     = var.target_group_stickiness_cookie_name != "" ? var.target_group_stickiness_cookie_name : null
    }
  }

  deregistration_delay = each.value.deregistration_delay

  tags = merge(local.enhanced_tags, var.target_group_tags, {
    TargetGroup = each.value.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Listeners for handling incoming traffic
resource "aws_lb_listener" "main" {
  for_each = { for listener in var.listeners : "${listener.port}-${listener.protocol}" => listener }

  load_balancer_arn = aws_lb.main.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.ssl_policy
  certificate_arn   = each.value.certificate_arn

  # Application layer protocol negotiation
  alpn_policy = var.listener_alpn_policy != "" ? [var.listener_alpn_policy] : null

  # Client certificate authentication
  dynamic "mutual_authentication" {
    for_each = var.listener_mutual_authentication.mode != "off" ? [var.listener_mutual_authentication] : []
    content {
      mode                   = mutual_authentication.value.mode
      trust_store_arn        = mutual_authentication.value.trust_store_arn
      ignore_client_certificate_expiry = mutual_authentication.value.ignore_client_certificate_expiry
    }
  }

  # Default action for unmatched requests
  dynamic "default_action" {
    for_each = [each.value.default_action]
    content {
      type             = default_action.value.type
      target_group_arn = default_action.value.type == "forward" ? (
        default_action.value.target_group_arn != null ? default_action.value.target_group_arn : 
        length(var.target_groups) > 0 ? aws_lb_target_group.main[var.target_groups[0].name].arn : null
      ) : null

      dynamic "fixed_response" {
        for_each = default_action.value.fixed_response != null ? [default_action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "redirect" {
        for_each = default_action.value.redirect != null ? [default_action.value.redirect] : []
        content {
          path        = redirect.value.path
          host        = redirect.value.host
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
          status_code = redirect.value.status_code
        }
      }
    }
  }

  tags = merge(local.enhanced_tags, var.listener_tags)
}

# Routing rules for listeners
resource "aws_lb_listener_rule" "main" {
  for_each = {
    for rule in flatten([
      for listener_key, listener in aws_lb_listener.main : [
        for rule in var.listeners[index(var.listeners, listener)] : {
          listener_key = listener_key
          rule         = rule
        }
      ]
    ]) : "${rule.listener_key}-${rule.rule.priority}" => rule
    if length(rule.rule.rules) > 0
  }

  listener_arn = aws_lb_listener.main[each.value.listener_key].arn
  priority     = each.value.rule.priority

  dynamic "action" {
    for_each = each.value.rule.rules
    content {
      type             = action.value.action.type
      target_group_arn = action.value.action.type == "forward" ? action.value.action.target_group_arn : null

      dynamic "fixed_response" {
        for_each = action.value.action.fixed_response != null ? [action.value.action.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "redirect" {
        for_each = action.value.action.redirect != null ? [action.value.action.redirect] : []
        content {
          path        = redirect.value.path
          host        = redirect.value.host
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
          status_code = redirect.value.status_code
        }
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.rule.rules
    content {
      dynamic "host_header" {
        for_each = condition.value.condition.field == "host-header" ? [condition.value.condition.values] : []
        content {
          values = host_header.value
        }
      }
      dynamic "path_pattern" {
        for_each = condition.value.condition.field == "path-pattern" ? [condition.value.condition.values] : []
        content {
          values = path_pattern.value
        }
      }
      dynamic "http_header" {
        for_each = condition.value.condition.field == "http-header" ? [condition.value.condition] : []
        content {
          http_header_name = condition.value.condition.http_header_name
          values           = condition.value.condition.values
        }
      }
    }
  }

  tags = local.common_tags
}

# WAF Web ACL association for additional security
resource "aws_wafv2_web_acl_association" "lb" {
  count        = var.waf_web_acl_arn != "" ? 1 : 0
  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.waf_web_acl_arn

  depends_on = [aws_lb.main]
}

# CloudWatch alarms for monitoring load balancer health
resource "aws_cloudwatch_metric_alarm" "lb_healthy_hosts" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.name}-healthy-hosts"
  comparison_operator = var.cloudwatch_alarm_comparison_operator
  evaluation_periods  = var.cloudwatch_alarm_evaluation_periods
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.cloudwatch_alarm_period
  statistic           = var.cloudwatch_alarm_statistic
  threshold           = var.cloudwatch_alarm_threshold
  alarm_description   = "Load balancer healthy host count is below threshold"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_ok_actions
  insufficient_data_actions = var.cloudwatch_alarm_insufficient_data_actions
  treat_missing_data  = var.cloudwatch_alarm_treat_missing_data

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = length(var.target_groups) > 0 ? aws_lb_target_group.main[var.target_groups[0].name].arn_suffix : ""
  }

  tags = merge(local.enhanced_tags, var.cloudwatch_alarm_tags)
}

resource "aws_cloudwatch_metric_alarm" "lb_unhealthy_hosts" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cloudwatch_alarm_evaluation_periods
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.cloudwatch_alarm_period
  statistic           = var.cloudwatch_alarm_statistic
  threshold           = 0
  alarm_description   = "Load balancer has unhealthy hosts"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_ok_actions
  insufficient_data_actions = var.cloudwatch_alarm_insufficient_data_actions
  treat_missing_data  = var.cloudwatch_alarm_treat_missing_data

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = length(var.target_groups) > 0 ? aws_lb_target_group.main[var.target_groups[0].name].arn_suffix : ""
  }

  tags = merge(local.enhanced_tags, var.cloudwatch_alarm_tags)
}

resource "aws_cloudwatch_metric_alarm" "lb_target_response_time" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.name}-target-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cloudwatch_alarm_evaluation_periods
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = var.cloudwatch_alarm_period
  statistic           = var.cloudwatch_alarm_statistic
  threshold           = 5
  alarm_description   = "Load balancer target response time is high"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_ok_actions
  insufficient_data_actions = var.cloudwatch_alarm_insufficient_data_actions
  treat_missing_data  = var.cloudwatch_alarm_treat_missing_data

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = length(var.target_groups) > 0 ? aws_lb_target_group.main[var.target_groups[0].name].arn_suffix : ""
  }

  tags = merge(local.enhanced_tags, var.cloudwatch_alarm_tags)
}

# Custom CloudWatch alarms for specific monitoring needs
resource "aws_cloudwatch_metric_alarm" "custom" {
  for_each = var.custom_cloudwatch_alarms

  alarm_name          = each.value.alarm_name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions
  treat_missing_data  = each.value.treat_missing_data
  unit                = each.value.unit
  extended_statistic  = each.value.extended_statistic
  datapoints_to_alarm = each.value.datapoints_to_alarm
  threshold_metric_id = each.value.threshold_metric_id

  dynamic "dimensions" {
    for_each = each.value.dimensions
    content {
      name  = dimensions.key
      value = dimensions.value
    }
  }

  tags = merge(local.enhanced_tags, var.cloudwatch_alarm_tags)
} 