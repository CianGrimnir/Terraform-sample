resource "aws_vpc" "main-tf" {
  cidr_block           = "${var.cidr_vpc}"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags {
    Name        = "main-vpc"
    Environment = "${var.environment_tags}"
  }
}

resource "aws_internet_gateway" "main-gw" {
  vpc_id = "${aws_vpc.main-tf.id}"

  tags {
    Name        = "VPC MAIN-IGW"
    Environment = "${var.environment_tags}"
  }
}

resource "aws_subnet" "main-subnet-public-01" {
  vpc_id                  = "${aws_vpc.main-tf.id}"
  cidr_block              = "${var.cidr_subnet-01}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.availability_zone-01}"

  tags {
    Name        = "main-public-subnet-02"
    Environment = "${var.environment_tags}"
  }
}

resource "aws_subnet" "main-subnet-public-02" {
  vpc_id                  = "${aws_vpc.main-tf.id}"
  cidr_block              = "${var.cidr_subnet-02}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.availability_zone-02}"

  tags {
    Name        = "main-public-subnet-01"
    Environment = "${var.environment_tags}"
  }
}

resource "aws_route_table" "main-public-rt" {
  vpc_id = "${aws_vpc.main-tf.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main-gw.id}"
  }

  tags {
    Name        = "Public Subnet RT"
    Environment = "${var.environment_tags}"
  }
}

resource "aws_route_table_association" "main-subnet-01-rt" {
  subnet_id      = "${aws_subnet.main-subnet-public-01.id}"
  route_table_id = "${aws_route_table.main-public-rt.id}"
}

resource "aws_route_table_association" "main-subnet-02-rt" {
  subnet_id      = "${aws_subnet.main-subnet-public-02.id}"
  route_table_id = "${aws_route_table.main-public-rt.id}"
}

resource "aws_security_group" "sg_80" {
  name        = "allow_http"
  description = "Allow http inbound traffic"

  #  vpc_id      = "vpc-e7de549d"
  vpc_id = "${aws_vpc.main-tf.id}"

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

  tags {
    Name        = "allow-http-ssh-access"
    Environment = "${var.environment_tags}"
  }
}

resource "aws_launch_configuration" "AS_launch_config" {
  image_id                    = "${var.instance_ami}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = true
  key_name                    = "rakesh-ec2-east-1"
  user_data                   = "${data.template_file.template_main.rendered}"

  //iam_instance_profile      = "yetToCreate"
  security_groups = ["${aws_security_group.sg_80.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "AS_apache" {
  launch_configuration = "${aws_launch_configuration.AS_launch_config.id}"
  vpc_zone_identifier  = ["${aws_subnet.main-subnet-public-01.id}", "${aws_subnet.main-subnet-public-02.id}"]
  min_size             = 2
  max_size             = 8
  desired_capacity     = 3
  target_group_arns    = ["${aws_alb_target_group.alb_targets.id}"]

  tag {
    key                 = "Name"
    value               = "apache_AS"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "AS-scale-up" {
  name                   = "AS-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.AS_apache.id}"
}

resource "aws_autoscaling_policy" "AS-scale-down" {
  name                   = "AS-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.AS_apache.id}"
}

resource "aws_lb" "apache_lb" {
  name               = "apache-alb"
  security_groups    = ["${aws_security_group.sg_80.id}"]
  load_balancer_type = "application"
  internal           = false

  subnets      = ["${aws_subnet.main-subnet-public-01.id}", "${aws_subnet.main-subnet-public-02.id}"]
  idle_timeout = 60

  tags {
    Name        = "apache-alb"
    Environment = "${var.environment_tags}"
  }

  access_logs {
    enabled = true
    bucket  = "${aws_s3_bucket.lb-log-bucket.id}"
    prefix  = "ELB-logs"
  }
}

resource "aws_alb_target_group" "alb_targets" {
  name     = "apache-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main-tf.id}"

  health_check {
    healthy_threshold   = 2
    interval            = 15
    path                = "/"
    port                = 80
    timeout             = 10
    unhealthy_threshold = 2
  }

  tags {
    Name        = "alb-target"
    Environment = "${var.environment_tags}"
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = "${aws_lb.apache_lb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.alb_targets.arn}"
  }
}

data "template_file" "template_main" {
  template = "${file("templates/exec-main.tpl")}"
}

output "ip" {
  value = {
    "apache-load-balancer" = "${aws_lb.apache_lb.dns_name}"
  }
}
