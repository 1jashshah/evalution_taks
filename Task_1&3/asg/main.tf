# Security Group for ASG instances
resource "aws_security_group" "asg_sg" {
  name   = "asg-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "asg_lt" {
  name_prefix   = "jash-asg-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>ASG Instance - Jash</h1>" > /var/www/html/index.html
  EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.asg_sg.id]
  }
}

resource "aws_autoscaling_group" "asg" {
  name = "jash-asg"

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }

  target_group_arns = var.target_group_arns

  tag {
    key                 = "Name"
    value               = "Jash-ASG-EC2"
    propagate_at_launch = true
  }
}

# Scaling Policies
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "cpu-scale-out"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "cpu-scale-in"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 60

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "asg-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20

  alarm_actions = [aws_autoscaling_policy.scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}
