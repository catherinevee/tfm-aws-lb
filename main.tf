locals {
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Name        = var.name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "tfm-aws-lb"
  })

  # CloudWatch log group name
  log_group_name = var.cloudwatch_log_group_name != "" ? var.cloudwatch_log_group_name : "/aws/loadbalancer/${var.name}"

  # Security group name
  security_group_name = "${var.name}-lb-sg"
}

# CloudWatch Log Group for Load Balancer logs
resource "aws_cloudwatch_log_group" "lb_logs" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = local.log_group_name
  retention_in_days = var.cloudwatch_log_retention_days

  tags = local.common_tags
}

# Security Group for Load Balancer
resource "aws_security_group" "lb" {
  count       = length(var.security_group_ids) == 0 ? 1 : 0
  name        = local.security_group_name
  description = "Security group for ${var.name} load balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.lb[0].id]
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.load_balancer_type == "application" ? var.enable_http2 : null
  idle_timeout                     = var.idle_timeout

  # Access logs configuration
  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [1] : []
    content {
      bucket  = var.access_logs.bucket
      prefix  = var.access_logs.prefix
      enabled = true
    }
  }

  tags = local.common_tags

  depends_on = [aws_cloudwatch_log_group.lb_logs]
}

# Target Groups
resource "aws_lb_target_group" "main" {
  for_each = { for tg in var.target_groups : tg.name => tg }

  name        = "${var.name}-${each.value.name}"
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = each.value.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = each.value.healthy_threshold
    interval            = each.value.health_check_interval
    matcher             = each.value.matcher
    path                = each.value.health_check_path
    port                = each.value.health_check_port
    protocol            = each.value.health_check_protocol
    timeout             = each.value.health_check_timeout
    unhealthy_threshold = each.value.unhealthy_threshold
  }

  # Stickiness configuration
  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      enabled         = stickiness.value.enabled
    }
  }

  deregistration_delay = each.value.deregistration_delay

  tags = merge(local.common_tags, {
    TargetGroup = each.value.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Listeners
resource "aws_lb_listener" "main" {
  for_each = { for listener in var.listeners : "${listener.port}-${listener.protocol}" => listener }

  load_balancer_arn = aws_lb.main.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.ssl_policy
  certificate_arn   = each.value.certificate_arn

  # Default action
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

  tags = local.common_tags
}

# Listener Rules
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

# WAF Web ACL Association (if provided)
resource "aws_wafv2_web_acl_association" "lb" {
  count        = var.waf_web_acl_arn != "" ? 1 : 0
  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.waf_web_acl_arn

  depends_on = [aws_lb.main]
}

# CloudWatch Alarms for Load Balancer Health
resource "aws_cloudwatch_metric_alarm" "lb_healthy_hosts" {
  count               = var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.name}-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Load balancer healthy host count is below threshold"
  alarm_actions       = []

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = length(var.target_groups) > 0 ? aws_lb_target_group.main[var.target_groups[0].name].arn_suffix : ""
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lb_unhealthy_hosts" {
  count               = var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Load balancer has unhealthy hosts"
  alarm_actions       = []

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = length(var.target_groups) > 0 ? aws_lb_target_group.main[var.target_groups[0].name].arn_suffix : ""
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lb_target_response_time" {
  count               = var.enable_cloudwatch_logs ? 1 : 0
  alarm_name          = "${var.name}-target-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "Load balancer target response time is high"
  alarm_actions       = []

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = length(var.target_groups) > 0 ? aws_lb_target_group.main[var.target_groups[0].name].arn_suffix : ""
  }

  tags = local.common_tags
} 