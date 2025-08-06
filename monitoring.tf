# CloudWatch dashboard for load balancer monitoring
resource "aws_cloudwatch_dashboard" "lb" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = "${var.name}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.this[0].arn_suffix],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Request Count and Response Codes"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.this[0].arn_suffix, { "stat": "p50" }],
            ["...", { "stat": "p90" }],
            ["...", { "stat": "p99" }]
          ]
          period = 300
          region = data.aws_region.current.name
          title  = "Target Response Time"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", aws_lb.this[0].arn_suffix],
            [".", "UnHealthyHostCount", ".", "."]
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Target Health"
        }
      }
    ]
  })
}

# CloudWatch alarms for load balancer monitoring
resource "aws_cloudwatch_metric_alarm" "http_5xx_errors" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.name}-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "HTTPCode_Target_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Sum"
  threshold          = var.error_threshold
  alarm_description  = "Alerts when HTTP 5XX errors exceed threshold"
  alarm_actions      = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.this[0].arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.name}-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "TargetResponseTime"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Average"
  threshold          = var.response_time_threshold
  alarm_description  = "Alerts when target response time exceeds threshold"
  alarm_actions      = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.this[0].arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  count = var.create_alarms ? 1 : 0

  alarm_name          = "${var.name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "UnHealthyHostCount"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Maximum"
  threshold          = var.unhealthy_host_threshold
  alarm_description  = "Alerts when unhealthy host count exceeds threshold"
  alarm_actions      = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.this[0].arn_suffix
  }
}
