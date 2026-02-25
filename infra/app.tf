# 1. Dynamic Data Lookups
# These allow Terraform to automatically find your Account ID and current Region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "apps" {
  type    = list(string)
  default = ["app-nginx", "app-python", "app-nodejs"]
}

# 2. Task Definitions
resource "aws_ecs_task_definition" "app" {
  for_each = toset(var.apps)
  family   = each.value
  
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = each.value
    # DYNAMIC IMAGE: Automatically uses your Account ID and the region set in your provider
    image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${each.value}:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = each.value == "app-nginx" ? 80 : (each.value == "app-python" ? 5000 : 3000)
      protocol      = "tcp"
    }]
  }])
}

# 3. ECS Services
resource "aws_ecs_service" "app" {
  for_each        = toset(var.apps)
  name            = each.value
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app[each.value].arn
  desired_count   = 2
  launch_type     = "EC2"

  #network_configuration {
    #subnets         = [aws_subnet.pub.id]
   #security_groups = [aws_security_group.ecs_sg.id]
    
    # FIXED: This must be false (or removed entirely) for the EC2 launch type.
    # Public IPs are handled by the EC2 host, not the individual ECS task.
    #assign_public_ip = false 
  #}

  # This ensures the service waits for the EC2 capacity to be ready
  depends_on = [aws_autoscaling_group.ecs_asg]
}
