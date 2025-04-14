locals {
  nginx_conf_b64 = base64encode(file("${path.module}/nginx.conf"))
  nginx_cloudfront_conf_b64 = base64encode(file("${path.module}/cloudfront_ips.conf"))
}

resource "aws_ecs_task_definition" "task" {
  family       = "${var.prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu          = 512
  memory       = 1024

  runtime_platform {
    cpu_architecture = "ARM64"
  }

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = <<DEFS
[
  {
    "name": "${var.prefix}",
    "image": "namespace/${var.prefix}:${var.image_version}",
    "repositoryCredentials": {
      "credentialsParameter": "${data.aws_secretsmanager_secret.ghcr_credentials.arn}"
    },
    "portMappings": [
      {
        "appProtocol": "http",
        "containerPort": 8080,
        "hostPort": 8080,
        "protocol": "tcp"
      }
    ],
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.logs.name}",
        "awslogs-region": "eu-south-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  },
  {
    "name": "${var.prefix}-nginx",
    "image": "nginx:latest",

    "environment": [
      {
        "name": "NGINX_CONF_BASE64",
        "value": "${local.nginx_conf_b64}"
      },
      {
        "name": "NGINX_CLOUDFRONT_CONF_BASE64",
        "value": "${local.nginx_cloudfront_conf_b64}"
      }
    ],

    "command": [
      "/bin/sh",
      "-c",
      "rm /etc/nginx/conf.d/default.conf && echo \"$NGINX_CONF_BASE64\" | base64 -d > /etc/nginx/conf.d/default.conf && echo \"$NGINX_CLOUDFRONT_CONF_BASE64\" | base64 -d > /etc/nginx/conf.d/cloudfront.conf && nginx -g 'daemon off;'"
    ],

    "portMappings": [
      {
        "appProtocol": "http",
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ],
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.nginx_logs.name}",
        "awslogs-region": "eu-south-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFS
}


resource "aws_ecs_service" "service" {
  name             = var.prefix
  cluster          = data.aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.task.arn
  desired_count    = 1
  platform_version = "LATEST"

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets = [""]
    security_groups = [aws_security_group.ecs_service_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "${var.prefix}-nginx"
    container_port   = 80
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [
    aws_lb_target_group.tg,
  ]
}

resource "aws_appautoscaling_target" "ecs_service" {
  max_capacity       = 100
  min_capacity       = 1
  resource_id        = "service/${data.aws_ecs_cluster.cluster.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "memory_policy" {
  name               = "memory-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
