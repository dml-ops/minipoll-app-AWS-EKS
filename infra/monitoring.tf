resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Turns "a container restarted" log lines into a number CloudWatch can alarm on
resource "aws_cloudwatch_log_metric_filter" "restarts" {
  name           = "${var.project_name}-container-restarts"
  log_group_name = "/aws/containerinsights/${module.eks.cluster_name}/performance"
  pattern        = "{ ($.Type = \"Pod\") && ($.pod_number_of_container_restarts > 0) }"

  metric_transformation {
    name          = "PodRestarts"
    namespace     = "minipoll"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "restarts" {
  alarm_name          = "${var.project_name}-container-restarts"
  namespace           = "minipoll"
  metric_name         = "PodRestarts"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
