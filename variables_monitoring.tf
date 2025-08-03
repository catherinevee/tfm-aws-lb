variable "create_dashboard" {
  description = "Whether to create CloudWatch dashboard for the load balancer"
  type        = bool
  default     = false
}

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms for the load balancer"
  type        = bool
  default     = false
}

variable "error_threshold" {
  description = "Threshold for HTTP 5XX errors alarm"
  type        = number
  default     = 10
}

variable "response_time_threshold" {
  description = "Threshold in seconds for target response time alarm"
  type        = number
  default     = 3
}

variable "unhealthy_host_threshold" {
  description = "Threshold for unhealthy hosts alarm"
  type        = number
  default     = 1
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "monitoring_tags" {
  description = "Additional tags for monitoring resources"
  type        = map(string)
  default     = {}
}
