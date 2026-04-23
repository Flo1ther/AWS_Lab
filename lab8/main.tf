provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

# -------------------------
# Security Groups
# -------------------------
resource "aws_security_group" "vm_sg" {
  name_prefix = "lab8-vm-sg-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "lab8-alb-sg-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.web_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "asg_sg" {
  name_prefix = "lab8-asg-sg-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "RDP admin"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------
# Task 1 - Two EC2 instances in different AZs
# -------------------------
resource "aws_instance" "vm1" {
  ami                    = data.aws_ami.windows.id
  instance_type          = var.vm_instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.vm_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "lab8-vm1"
  }
}

resource "aws_instance" "vm2" {
  ami                    = data.aws_ami.windows.id
  instance_type          = var.vm_instance_type
  subnet_id              = data.aws_subnets.default.ids[1]
  vpc_security_group_ids = [aws_security_group.vm_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "lab8-vm2"
  }
}

# -------------------------
# Task 2 - Extra EBS disk for vm1
# -------------------------
resource "aws_ebs_volume" "vm1_disk1" {
  availability_zone = aws_instance.vm1.availability_zone
  size              = 32
  type              = "gp3"

  tags = {
    Name = "lab8-vm1-disk1"
  }
}

resource "aws_volume_attachment" "vm1_disk1_attach" {
  device_name = "xvdf"
  volume_id   = aws_ebs_volume.vm1_disk1.id
  instance_id = aws_instance.vm1.id
}

# -------------------------
# Task 3 - Load Balancer for scaled instances
# -------------------------
resource "aws_lb" "vmss_alb" {
  name               = "lab8-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = slice(data.aws_subnets.default.ids, 0, 2)
}

resource "aws_lb_target_group" "vmss_tg" {
  name     = "lab8-tg-${random_id.suffix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
    port = "80"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.vmss_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vmss_tg.arn
  }
}

# -------------------------
# Task 3 - Launch Template + Auto Scaling Group
# -------------------------
resource "aws_launch_template" "vmss_lt" {
  name_prefix   = "lab8-lt-"
  image_id      = data.aws_ami.windows.id
  instance_type = var.asg_instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  user_data = base64encode(<<-EOF
              <powershell>
              Install-WindowsFeature -name Web-Server -IncludeManagementTools
              Set-Content -Path C:\inetpub\wwwroot\index.html -Value "Hello from Auto Scaling instance"
              </powershell>
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "lab8-asg-instance"
    }
  }
}

resource "aws_autoscaling_group" "vmss_asg" {
  name                = "lab8-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 10
  vpc_zone_identifier = slice(data.aws_subnets.default.ids, 0, 2)
  target_group_arns   = [aws_lb_target_group.vmss_tg.arn]
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.vmss_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "lab8-asg-instance"
    propagate_at_launch = true
  }
}

# -------------------------
# Task 4 - Autoscaling policies and alarms
# -------------------------
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "lab8-scale-out"
  autoscaling_group_name = aws_autoscaling_group.vmss_asg.name
  adjustment_type        = "PercentChangeInCapacity"
  scaling_adjustment     = 50
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "lab8-scale-in"
  autoscaling_group_name = aws_autoscaling_group.vmss_asg.name
  adjustment_type        = "PercentChangeInCapacity"
  scaling_adjustment     = -50
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "lab8-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale out when CPU > 70%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.vmss_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "lab8-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Scale in when CPU < 30%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.vmss_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}