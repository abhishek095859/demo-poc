# 1. Fetch the latest ECS-Optimized AMI for Mumbai (ap-south-1)
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# 2. The Cluster
resource "aws_ecs_cluster" "main" {
  name = "my-app-cluster"
}

# 3. IAM Role for the EC2 Instances to join ECS
resource "aws_iam_role" "ecs_node_role" {
  name = "ecs-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# FIXED: Added the double colon (::) to the policy_arn
resource "aws_iam_role_policy_attachment" "ecs_node_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node_profile" {
  name = "ecs-node-profile"
  role = aws_iam_role.ecs_node_role.name
}

# 4. Launch Template
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = data.aws_ssm_parameter.ecs_ami.value # Uses the dynamic ID for Mumbai
  instance_type = "t3.micro"
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_node_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  # This joins the EC2 instance to your ECS cluster at boot
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  )
}

# 5. Auto Scaling Group
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
    value               = "true"
    propagate_at_launch = true
  }
}
