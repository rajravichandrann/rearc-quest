resource "aws_ecr_repository" "quest_rearc_ecr_repo" {
  name = "quest-repo"
}

resource "aws_ecs_cluster" "quest_cluster" {
  name = "quest-cluster"
}

resource "aws_ecs_task_definition" "quest_task" {
  family                   = "quest-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "quest-task",
      "image": "${aws_ecr_repository.quest_rearc_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256,
      "environment": [
        {
          "name": "SECRET_WORD",
          "value": "TwelveFactor"
        }
      ]
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole1"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "quest_service" {
  name            = "quest-service"
  cluster         = aws_ecs_cluster.quest_cluster.id
  task_definition = aws_ecs_task_definition.quest_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets          = var.subnet_ids
    assign_public_ip = true
    security_groups  = ["${aws_security_group.service_security_group.id}"] 
  }
  load_balancer {
    target_group_arn = "${aws_lb_target_group.quest_target_group.arn}"
    container_name   = aws_ecs_task_definition.quest_task.family
    container_port   = 3000 # Specifying the container port
  }
  depends_on = [aws_lb_listener.listener]
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0 
    to_port     = 0 
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_alb" "application_load_balancer" {
  name               = "quest-lb-tf" # Naming our load balancer
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = ["${aws_security_group.load_balancer_security_group.id}"]
}


resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = var.vpc_id
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_lb_target_group" "quest_target_group" {
  name        = "quest-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    matcher = "200"
    path    = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quest_target_group.arn
  }
}