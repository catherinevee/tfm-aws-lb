variable "create_dashboard" {
  description = "Create CloudWatch dashboard for load balancer monitoring"
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Create CloudWatch alarms for load balancer health"
  type        = bool
  default     = false
}

variable "error_threshold" {
  description = "HTTP 5XX errors threshold for alarm triggering"
  type        = number
  default     = 10
}

variable "response_time_threshold" {
  description = "Target response time threshold in seconds"
  type        = number
  default     = 3
}

variable "unhealthy_host_threshold" {
  description = "Unhealthy host count threshold for alarm"
  type        = number
  default     = 1
}

variable "alarm_actions" {
  description = "SNS topic ARNs or other actions for alarm notifications"
  type        = list(string)
  default     = []
}

variable "monitoring_tags" {
  description = "Tags for monitoring resources"
  type        = map(string)
  default     = {}
}
