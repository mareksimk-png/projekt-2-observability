# SNS Topic pro notifikace
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name        = "${var.project_name}-alerts"
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# E-mailová subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Output - ARN topicu
output "sns_topic_arn" {
  description = "ARN SNS topicu pro notifikace"
  value       = aws_sns_topic.alerts.arn
}