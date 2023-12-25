provider "aws" {
#  region = var.region
  region     = "${var.region}"
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
}

provider "vault" {}

data "terraform_remote_state" "admin" {
  backend = "local"
  config = {
    path = var.vault_state_path
  }
}

data "vault_aws_access_credentials" "creds" {
  backend = data.terraform_remote_state.admin.outputs.backend
  role    = data.terraform_remote_state.admin.outputs.role
}

resource "aws_launch_configuration" "myasg" {
  image_id = "ami-09eebd0b9bd845bf1"  # Replace with your desired AMI ID
  instance_type = "t2.micro"          # Adjust instance type as needed
  key_name = "myEC2key"          # Replace with your key pair name
  security_groups = ["sg-045a0a59d9c0db31b"]
  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              # echo "<h1> Richard's Demo from $(hostname -f)</h1>" >> /var/www/html/index.html
              echo '<img src="https://tf-web-s3rx.s3.ap-southeast-2.amazonaws.com/sbs-world-cup.jpeg" alt="sbs soccer">' >> /var/www/html/index.html
              echo "<h1> Richard's Demo from $(hostname -f) <br> Created on $(date) </h1>" >> /var/www/html/index.html
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "myasg" {
  desired_capacity     = 3
  max_size             = 3
  min_size             = 3

  vpc_zone_identifier  = ["subnet-06ee8f3c4d33925b3", "subnet-0e3ced40d9f75cb0d", "subnet-0d795114d9b0eafdb"]  # Replace with your subnet IDs

  launch_configuration = aws_launch_configuration.myasg.id

  health_check_type          = "EC2"
  health_check_grace_period  = 300
}

resource "aws_lb" "myasg" {
  name               = "myasg-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myasg.id]  # Add your security groups if needed

  enable_deletion_protection = false

  enable_http2 = true

  subnets = ["subnet-06ee8f3c4d33925b3", "subnet-0e3ced40d9f75cb0d", "subnet-0d795114d9b0eafdb"]  # Replace with your subnet IDs
}

resource "aws_lb_listener" "myasg" {
  load_balancer_arn = aws_lb.myasg.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.myasg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "myasg" {
  name        = "myasg-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-0a61f4c9fb9685de1"  # Replace with your VPC ID
}

resource "aws_autoscaling_attachment" "myasg" {
  autoscaling_group_name = aws_autoscaling_group.myasg.name
  lb_target_group_arn   = aws_lb_target_group.myasg.arn
}

resource "aws_security_group" "myasg" {
  name        = "myasg-lb-sg"
  description = "My ASG LB Security Group"
  vpc_id      = "vpc-0a61f4c9fb9685de1"  # Replace with your VPC ID

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
