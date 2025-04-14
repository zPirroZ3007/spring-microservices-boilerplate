data "aws_lb" "alb" {
  name = "alb"
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "${var.prefix}-ecs-service-sg"
  description = "SG per ECS servizio telegram bot"

  ingress {
    description = "Allow HTTP traffic from ALB"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP traffic from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-service-sg"
  }
}

# Creazione del Target Group
resource "aws_lb_target_group" "tg" {
  name        = "${var.prefix}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    path                = "/api/${element(split("-", var.prefix), 1)}/actuator/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }

  tags = {
    Name = "${var.prefix}-tg"
  }
}

locals {
  extracted_path = element(split("-", var.prefix), 1)  # Extract the second part
}


resource "aws_lb_listener_rule" "service1_host_rule" {
  listener_arn = ""
  priority     = var.rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = ["my.app"]
    }
  }

  condition {
    path_pattern {
      values = ["/api/${element(split("-", var.prefix), 1)}/*"]
    }
  }
}
