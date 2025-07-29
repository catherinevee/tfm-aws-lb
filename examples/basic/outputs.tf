output "load_balancer_id" {
  description = "The ID of the load balancer"
  value       = module.alb_basic.load_balancer_id
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb_basic.load_balancer_dns_name
}

output "load_balancer_arn" {
  description = "The ARN of the load balancer"
  value       = module.alb_basic.load_balancer_arn
}

output "target_group_arns" {
  description = "Map of target group names to ARNs"
  value       = module.alb_basic.target_group_arns
}

output "security_group_id" {
  description = "The ID of the security group created for the load balancer"
  value       = module.alb_basic.security_group_id
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.alb_basic.cloudwatch_log_group_name
} 