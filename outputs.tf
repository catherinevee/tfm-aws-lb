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