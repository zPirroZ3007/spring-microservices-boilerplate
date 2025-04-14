resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/${var.prefix}-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = "/ecs/${var.prefix}-nginx-logs"
}