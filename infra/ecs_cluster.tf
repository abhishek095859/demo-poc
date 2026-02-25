# 1. The Cluster
resource "aws_ecs_cluster" "main" {
  name = "my-app-cluster"
}

# 2. IAM Role for the EC2 Instances to join ECS
resource "aws_iam_role" "ecs_node_role" {
  name = "ecs-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_node_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam:aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node_profile" {
  name = "ecs-node-profile"
  role = aws_iam_role.ecs_node_role.name
}

# 3. Launch Template (What kind of EC2?)
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 ECS-Optimized
  instance_type = "t3.micro"
  iam_instance_profile { name = aws_iam_instance_profile.ecs_node_profile.name }
  vpc_security_group_ids = [aws_security_group.ecs_sg.id]
  user_data = base64encode("#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config")
}

# 4. Auto Scaling Group
resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = [aws_subnet.pub.id]
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true" # Note: ASG tag values must be strings
    propagate_at_launch = true
  }
}