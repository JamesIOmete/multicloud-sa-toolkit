locals {
  base_name = "${var.base_name}-${var.sandbox_id}"
  tags = merge({
    toolkit    = "multicloud-sa-toolkit",
    use_case   = "04-ephemeral-sandbox",
    env        = var.env,
    owner      = var.owner,
    managed_by = "terraform",
    sandbox_id = var.sandbox_id
  }, var.additional_tags)
}

resource "aws_ecs_cluster" "sandbox" {
  name = "${local.base_name}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "task" {
  name              = "/mcsa/${local.base_name}/tasks"
  retention_in_days = var.log_retention_days

  tags = local.tags
}

resource "aws_iam_role" "task_execution" {
  name = "${local.base_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "sandbox" {
  family                   = "${local.base_name}-task"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "token-app"
      image = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.task.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "sandbox"
        }
      }
      environment = [
        {
          name  = "SANDBOX_ID"
          value = var.sandbox_id
        }
      ]
    }
  ])
}

resource "aws_lb" "sandbox" {
  name               = substr("${local.base_name}-alb", 0, 32)
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  tags = local.tags
}

resource "aws_lb_target_group" "sandbox" {
  name_prefix = substr("${local.base_name}-", 0, 6)
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "sandbox" {
  load_balancer_arn = aws_lb.sandbox.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sandbox.arn
  }
}

resource "aws_ecs_service" "sandbox" {
  name            = "${local.base_name}-service"
  cluster         = aws_ecs_cluster.sandbox.arn
  task_definition = aws_ecs_task_definition.sandbox.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sandbox.arn
    container_name   = "token-app"
    container_port   = var.container_port
  }

  tags = local.tags
}
