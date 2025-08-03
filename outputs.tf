output "load_balancer_id" {
  description = "The ID of the load balancer"
  value       = aws_lb.main.id
}

output "load_balancer_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "load_balancer_arn_suffix" {
  description = "The ARN suffix of the load balancer"
  value       = aws_lb.main.arn_suffix
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "load_balancer_name" {
  description = "The name of the load balancer"
  value       = aws_lb.main.name
}

output "load_balancer_type" {
  description = "The type of load balancer"
  value       = aws_lb.main.load_balancer_type
}

output "load_balancer_internal" {
  description = "Whether the load balancer is internal"
  value       = aws_lb.main.internal
}

output "target_group_arns" {
  description = "Map of target group names to ARNs"
  value = {
    for name, tg in aws_lb_target_group.main : name => tg.arn
  }
}

output "target_group_names" {
  description = "Map of target group names to full names"
  value = {
    for name, tg in aws_lb_target_group.main : name => tg.name
  }
}

output "listener_arns" {
  description = "Map of listener port-protocol to ARNs"
  value = {
    for key, listener in aws_lb_listener.main : key => listener.arn
  }
}

output "security_group_id" {
  description = "The ID of the security group created for the load balancer"
  value       = length(var.security_group_ids) == 0 ? aws_security_group.lb[0].id : null
}

output "security_group_arn" {
  description = "The ARN of the security group created for the load balancer"
  value       = length(var.security_group_ids) == 0 ? aws_security_group.lb[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.lb_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.lb_logs[0].arn : null
}

output "waf_web_acl_association_id" {
  description = "The ID of the WAF Web ACL association"
  value       = var.waf_web_acl_arn != "" ? aws_wafv2_web_acl_association.lb[0].id : null
}

output "cloudwatch_alarm_arns" {
  description = "Map of CloudWatch alarm names to ARNs"
  value = var.enable_cloudwatch_logs ? {
    healthy_hosts       = aws_cloudwatch_metric_alarm.lb_healthy_hosts[0].arn
    unhealthy_hosts     = aws_cloudwatch_metric_alarm.lb_unhealthy_hosts[0].arn
    target_response_time = aws_cloudwatch_metric_alarm.lb_target_response_time[0].arn
  } : {}
}

output "tags" {
  description = "A map of tags assigned to the load balancer"
  value       = aws_lb.main.tags
}

# Enhanced Outputs
output "load_balancer_description" {
  description = "Description of the load balancer"
  value       = var.load_balancer_description
}

output "load_balancer_attributes" {
  description = "Enhanced attributes of the load balancer"
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
  description = "Enhanced attributes of target groups"
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
  description = "Enhanced attributes of listeners"
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
  description = "Enhanced attributes of the security group"
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
  description = "CloudWatch configuration details"
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
  description = "WAF configuration details"
  value = {
    web_acl_arn = var.waf_web_acl_arn
    associated  = var.waf_web_acl_arn != ""
  }
}

output "enhanced_features" {
  description = "Status of enhanced features"
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
  description = "Comprehensive configuration summary"
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