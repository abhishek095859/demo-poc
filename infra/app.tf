variable "apps" {
  default = ["app-nginx", "app-python", "app-nodejs"]
}

resource "aws_ecs_task_definition" "app" {
  for_each = toset(var.apps)
  family   = each.value
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = each.value
    image     = "183295435445.dkr.ecr.us-east-1.amazonaws.com/${each.value}:latest"
    essential = true
    portMappings = [{ containerPort = 80, hostPort = 80 }]
  }])
}

resource "aws_ecs_service" "app" {
  for_each        = toset(var.apps)
  name            = each.value
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app[each.value].arn
  desired_count   = 1
  launch_type     = "EC2"
  network_configuration {
    subnets          = [aws_subnet.pub.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}