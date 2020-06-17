provider "aws" {
access_key = "****************"
secret_key = "*********************"
region = "us-west-2"
}

resource "aws_security_group" "ec2_security_group" {
  name        = "EC2-SG"
  description = "Internet reaching access for EC2 Instances"
  vpc_id      = "vpc-*******"

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server_1" {
 ami_id = "ami-0e34e7b9ca0ace12d"
 instance_type = "t2.micro"
 security_group = ${"aws_security_group.ec2_security_group.id"}
 subnet_id = "subnet-******"
}

#subnet -subnet 1

resource "aws_instance" "server_2" {
 ami_id = "ami-0e34e7b9ca0ace12d"
 instance_type = "t2.micro"
 security_group = ${"aws_security_group.ec2_security_group.id"}
 subnet_id = "subnet-*******"
}


#subnet 2

resource "aws_security_group" "elb_security_group" {
  name = "ELB-SG"
  description = "ELB Security Group"
  vpc_id = "vpc-a43959dc"

  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow web traffic to load balancer"
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "my-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "my-test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "vpc-********"
}

resource "aws_lb_target_group_attachment" "my-alb-target-group-attachment1" {
  target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
  target_id        = "${aws_instance.server_1.id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "my-alb-target-group-attachment2" {
  target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
  target_id        = "${aws_instance.server_2.id}"
  port             = 80
}

resource "aws_lb" "my-aws-alb" {
  name     = "my-test-alb"
  internal = false

  security_groups = "${aws_security_group.elb_security_group.id}"

  subnets = [ "subnet-*******", "subnet-********" ]
    tags = {
    Name = "my-test-alb"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

#both subnet 1 & 2 needs to be mentioned here

resource "aws_lb_listener" "my-test-alb-listner" {
  load_balancer_arn = "${aws_lb.my-aws-alb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
  }
}


