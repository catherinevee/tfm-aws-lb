output "load_balancer_id" {
  description = "Load balancer resource ID"
  value       = aws_lb.main.id
}

output "load_balancer_arn" {
  description = "Load balancer ARN for IAM policies and references"
  value       = aws_lb.main.arn
}

output "load_balancer_arn_suffix" {
  description = "Load balancer ARN suffix for CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
}

output "load_balancer_dns_name" {
  description = "DNS name for accessing the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Route53 hosted zone ID for DNS configuration"
  value       = aws_lb.main.zone_id
}

output "load_balancer_name" {
  description = "Load balancer name"
  value       = aws_lb.main.name
}

output "load_balancer_type" {
  description = "Load balancer type (application or network)"
  value       = aws_lb.main.load_balancer_type
}

output "load_balancer_internal" {
  description = "True if internal load balancer, false if internet-facing"
  value       = aws_lb.main.internal
}

output "target_group_arns" {
  description = "Target group ARNs mapped by name"
  value = {
    for name, tg in aws_lb_target_group.main : name => tg.arn
  }
}

output "target_group_names" {
  description = "Full target group names mapped by short name"
  value = {
    for name, tg in aws_lb_target_group.main : name => tg.name
  }
}

output "listener_arns" {
  description = "Listener ARNs mapped by port-protocol combination"
  value = {
    for key, listener in aws_lb_listener.main : key => listener.arn
  }
}

output "security_group_id" {
  description = "Security group ID (null if using existing security groups)"
  value       = length(var.security_group_ids) == 0 ? aws_security_group.lb[0].id : null
}

output "security_group_arn" {
  description = "Security group ARN (null if using existing security groups)"
  value       = length(var.security_group_ids) == 0 ? aws_security_group.lb[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for access logs"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.lb_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN for IAM permissions"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.lb_logs[0].arn : null
}

output "waf_web_acl_association_id" {
  description = "WAF Web ACL association ID (null if no WAF configured)"
  value       = var.waf_web_acl_arn != "" ? aws_wafv2_web_acl_association.lb[0].id : null
}

output "cloudwatch_alarm_arns" {
  description = "CloudWatch alarm ARNs for monitoring"
  value = var.enable_cloudwatch_logs ? {
    healthy_hosts       = aws_cloudwatch_metric_alarm.lb_healthy_hosts[0].arn
    unhealthy_hosts     = aws_cloudwatch_metric_alarm.lb_unhealthy_hosts[0].arn
    target_response_time = aws_cloudwatch_metric_alarm.lb_target_response_time[0].arn
  } : {}
}

output "tags" {
  description = "Tags applied to the load balancer"
  value       = aws_lb.main.tags
}

# Additional Outputs
output "load_balancer_description" {
  description = "Load balancer description if provided"
  value       = var.load_balancer_description
}

output "load_balancer_attributes" {
  description = "Key load balancer configuration attributes"
  value = {
    name                        = aws_lb.main.name
    internal                    = aws_lb.main.internal
    load_balancer_type          = aws_lb.main.load_balancer_type
    enable_deletion_protection  = aws_lb.main.enable_deletion_protection
    enable_cross_zone_load_balancing = aws_lb.main.enable_cross_zone_load_balancing
    enable_http2                = aws_lb.main.enable_http2
    idle_timeout                = aws_lb.main.idle_timeout
    desync_mitigation_mode      = var.desync_mitigation_mode
    customer_owned_ipv4_pool    = var.customer_owned_ipv4_pool
  }
}

output "target_group_attributes" {
  description = "Target group configuration details"
  value = {
    for name, tg in aws_lb_target_group.main : name => {
      arn                           = tg.arn
      name                          = tg.name
      port                          = tg.port
      protocol                      = tg.protocol
      target_type                   = tg.target_type
      vpc_id                        = tg.vpc_id
      load_balancing_algorithm_type = var.target_group_load_balancing_algorithm_type
      slow_start                    = var.target_group_slow_start
      proxy_protocol_v2             = var.target_group_proxy_protocol_v2
      lambda_multi_value_headers_enabled = var.target_group_lambda_multi_value_headers_enabled
    }
  }
}

output "listener_attributes" {
  description = "Listener configuration details"
  value = {
    for key, listener in aws_lb_listener.main : key => {
      arn         = listener.arn
      port        = listener.port
      protocol    = listener.protocol
      ssl_policy  = listener.ssl_policy
      alpn_policy = var.listener_alpn_policy
    }
  }
}

output "security_group_attributes" {
  description = "Security group configuration details (null if using existing security groups)"
  value = length(var.security_group_ids) == 0 ? {
    id          = aws_security_group.lb[0].id
    arn         = aws_security_group.lb[0].arn
    name        = aws_security_group.lb[0].name
    description = aws_security_group.lb[0].description
    vpc_id      = aws_security_group.lb[0].vpc_id
    ingress_rules_count = length(aws_security_group.lb[0].ingress)
    egress_rules_count  = length(aws_security_group.lb[0].egress)
  } : null
}

output "cloudwatch_configuration" {
  description = "CloudWatch logging and monitoring configuration"
  value = {
    log_group_name     = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.lb_logs[0].name : null
    log_group_arn      = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.lb_logs[0].arn : null
    retention_days     = var.cloudwatch_log_retention_days
    kms_key_id         = var.cloudwatch_log_group_kms_key_id
    alarms_enabled     = var.enable_cloudwatch_alarms
    custom_alarms_count = length(var.custom_cloudwatch_alarms)
  }
}

output "waf_configuration" {
  description = "WAF integration status and configuration"
  value = {
    web_acl_arn = var.waf_web_acl_arn
    associated  = var.waf_web_acl_arn != ""
  }
}

output "enhanced_features" {
  description = "Status of optional enterprise features"
  value = {
    compliance_tagging_enabled = var.enable_compliance_tagging
    enhanced_monitoring_enabled = var.enable_enhanced_monitoring
    request_tracing_enabled = var.enable_request_tracing
    performance_insights_enabled = var.enable_performance_insights
    shield_advanced_enabled = var.enable_shield_advanced
    guardduty_integration_enabled = var.enable_guardduty_integration
    security_hub_integration_enabled = var.enable_security_hub_integration
    cost_optimization_enabled = var.enable_cost_optimization
    auto_scaling_enabled = var.enable_auto_scaling
    resource_policies_enabled = var.enable_resource_policies
  }
}

output "configuration_summary" {
  description = "Summary of load balancer configuration and features"
  value = {
    load_balancer = {
      name        = aws_lb.main.name
      type        = aws_lb.main.load_balancer_type
      internal    = aws_lb.main.internal
      dns_name    = aws_lb.main.dns_name
      zone_id     = aws_lb.main.zone_id
    }
    target_groups_count = length(var.target_groups)
    listeners_count     = length(var.listeners)
    security_groups_count = length(var.security_group_ids) > 0 ? length(var.security_group_ids) : 1
    cloudwatch_enabled  = var.enable_cloudwatch_logs
    alarms_enabled      = var.enable_cloudwatch_alarms
    waf_enabled         = var.waf_web_acl_arn != ""
    enhanced_features   = var.enable_enhanced_monitoring || var.enable_compliance_tagging || var.enable_cost_optimization
  }
} 