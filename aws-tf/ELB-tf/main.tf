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

resource "aws_route_table_association" "main-subnet-A-rt" {
  subnet_id      = "${aws_subnet.main-subnet-public-01.id}"
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

resource "aws_lb_target_group_attachment" "alb_target_attachment-01" {
  target_group_arn = "${aws_alb_target_group.alb_targets.arn}"
  target_id        = "${aws_instance.apache-main.id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "alb_target_attachment-02" {
  target_group_arn = "${aws_alb_target_group.alb_targets.arn}"
  target_id        = "${aws_instance.apache-blog.id}"
  port             = 80
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

data "template_file" "template_blog" {
  template = "${file("templates/exec-blog.tpl")}"
}

output "ip" {
  value = {
    //    "apache-main public ip" = "${aws_instance.apache-main.public_ip}"
    "apache-load-balancer" = "${aws_lb.apache_lb.dns_name}"
  }
}
