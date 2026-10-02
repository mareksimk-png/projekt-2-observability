# ============================================
# Log Metric Filter pro Nginx 5xx chyby
# ============================================
resource "aws_cloudwatch_log_metric_filter" "nginx_5xx" {
  name           = "${var.project_name}-nginx-5xx-errors"
  log_group_name = "/aws/ec2/${var.project_name}/nginx-access"
  pattern = " 500 "
  metric_transformation {
    name      = "Nginx5xxErrors"
    namespace = "${var.project_name}/Custom"
    value     = "1"
  }
}

# ============================================
# Alarm: CPU > 80% po 5 minut
# ============================================
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "cpu_usage_user"
  namespace           = "${var.project_name}/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "CPU > ${var.cpu_threshold}% po 5 minut"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = local.projekt_1_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.project_name}-cpu-high"
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# ============================================
# Alarm: Disk > 85%
# ============================================
resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "${var.project_name}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "${var.project_name}/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.disk_threshold
  alarm_description   = "Disk > ${var.disk_threshold}% na /"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = local.projekt_1_instance_id
    path       = "/"
    device     = "xvda1"
    fstype     = "xfs"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.project_name}-disk-high"
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# ============================================
# Alarm: Nginx 5xx chyby > 10 za 5 minut
# ============================================
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CPU Utilization"
          region = var.aws_region
          metrics = [
            ["${var.project_name}/EC2", "cpu_usage_user", "host", "ip-10-0-2-180.eu-central-1.compute.internal", "cpu", "cpu-total", { label = "User" }],
            [".", "cpu_usage_system", ".", ".", ".", ".", { label = "System" }],
            [".", "cpu_usage_idle", ".", ".", ".", ".", { label = "Idle" }]
          ]
          view   = "timeSeries"
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Memory Utilization"
          region = var.aws_region
          metrics = [
            ["${var.project_name}/EC2", "mem_used_percent", "host", "ip-10-0-2-180.eu-central-1.compute.internal", { label = "Used %" }]
          ]
          view   = "timeSeries"
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Disk Utilization (root /)"
          region = var.aws_region
          metrics = [
            ["${var.project_name}/EC2", "disk_used_percent", "host", "ip-10-0-2-180.eu-central-1.compute.internal", "path", "/", "device", "nvme0n1p1", "fstype", "xfs", { label = "Used %" }]
          ]
          view   = "timeSeries"
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Network Traffic"
          region = var.aws_region
          metrics = [
            ["${var.project_name}/EC2", "net_bytes_sent", "host", "ip-10-0-2-180.eu-central-1.compute.internal", { label = "Sent" }],
            [".", "net_bytes_recv", ".", ".", { label = "Received" }]
          ]
          view   = "timeSeries"
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Nginx 5xx Errors (per 5 min)"
          region = var.aws_region
          metrics = [
            ["${var.project_name}/Custom", "Nginx5xxErrors", { label = "5xx Errors", stat = "Sum" }]
          ]
          view   = "timeSeries"
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Alarm Status"
          region = var.aws_region
          metrics = [
            ["AWS/CloudWatch", "AlarmCount", "AlarmName", "${var.project_name}-cpu-high", { label = "CPU" }],
            [".", "AlarmCount", ".", "${var.project_name}-disk-high", { label = "Disk" }],
            [".", "AlarmCount", ".", "${var.project_name}-nginx-5xx", { label = "Nginx 5xx" }]
          ]
          view   = "singleValue"
          period = 300
          stat   = "Maximum"
        }
      }
    ]
  })
}