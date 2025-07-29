output "load_balancer_id" {
  description = "The ID of the load balancer"
  value       = module.nlb.load_balancer_id
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.nlb.load_balancer_dns_name
}

output "load_balancer_arn" {
  description = "The ARN of the load balancer"
  value       = module.nlb.load_balancer_arn
}

output "target_group_arns" {
  description = "Map of target group names to ARNs"
  value       = module.nlb.target_group_arns
}

output "listener_arns" {
  description = "Map of listener port-protocol to ARNs"
  value       = module.nlb.listener_arns
}

output "security_group_id" {
  description = "The ID of the security group created for the load balancer"
  value       = module.nlb.security_group_id
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.nlb.cloudwatch_log_group_name
}

output "load_balancer_type" {
  description = "The type of load balancer"
  value       = module.nlb.load_balancer_type
} 