resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "cloudpipe-cloudwatch-logs"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/cloudpipe/app"
  retention_in_days = 3
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "cloudpipe-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU above 80% for 1 minute"
  dimensions = {
    InstanceId = aws_instance.pyflask_ec2.id
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name          = "cloudpipe-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 instance failed a status check"
  dimensions = {
    InstanceId = aws_instance.pyflask_ec2.id
  }
}

resource "aws_cloudwatch_log_metric_filter" "app_log_filter" {
  name           = "cloudpipe-app-errors"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "AppErrorCount"
    namespace = "CloudPipe"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_error_alarm" {
  alarm_name          = "cloudpipe-app-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "AppErrorCount"
  namespace           = "CloudPipe"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm when application logs contains ERROR"
}
