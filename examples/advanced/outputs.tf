output "load_balancer_id" {
  description = "The ID of the load balancer"
  value       = module.alb_advanced.load_balancer_id
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb_advanced.load_balancer_dns_name
}

output "load_balancer_arn" {
  description = "The ARN of the load balancer"
  value       = module.alb_advanced.load_balancer_arn
}

output "target_group_arns" {
  description = "Map of target group names to ARNs"
  value       = module.alb_advanced.target_group_arns
}

output "listener_arns" {
  description = "Map of listener port-protocol to ARNs"
  value       = module.alb_advanced.listener_arns
}

output "security_group_id" {
  description = "The ID of the security group created for the load balancer"
  value       = module.alb_advanced.security_group_id
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.alb_advanced.cloudwatch_log_group_name
}

output "waf_web_acl_association_id" {
  description = "The ID of the WAF Web ACL association"
  value       = module.alb_advanced.waf_web_acl_association_id
}

output "cloudwatch_alarm_arns" {
  description = "Map of CloudWatch alarm names to ARNs"
  value       = module.alb_advanced.cloudwatch_alarm_arns
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket for access logs"
  value       = aws_s3_bucket.lb_logs.bucket
}

output "waf_web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
} 