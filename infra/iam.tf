resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.prefix}-ecs-task-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_execution_inline" {
  name = "${var.prefix}-ecs-task-execution-inline"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Action" : "secretsmanager:GetSecretValue",
        "Effect" : "Allow",
        "Resource" : data.aws_secretsmanager_secret.ghcr_credentials.arn
      },
      {
        "Action" : "secretsmanager:*",
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_cloudwatch_log_group.logs.arn}:*"
      },
      {
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_cloudwatch_log_group.nginx_logs.arn}:*"
      },
      {
        "Action" : [
          "s3:GetObject"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.env_bucket_name}/${var.prefix}.env"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_execution_role_policy_attach" {
  name       = "${var.prefix}-ecs-execution-role-policy-attach"
  roles = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
