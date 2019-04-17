resource "aws_instance" "apache-main" {
  ami                         = "${var.instance_ami}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${aws_subnet.main-subnet-public-01.id}"
  associate_public_ip_address = true
  key_name                    = "rakesh-ec2-east-1"
  user_data                   = "${data.template_file.template_main.rendered}"

  //iam_instance_profile      = "yetToCreate"
  vpc_security_group_ids = ["${aws_security_group.sg_80.id}"]

  tags = {
    Name        = "main"
    Environment = "${var.environment_tags}"
  }
}

resource "aws_instance" "apache-blog" {
  ami                         = "ami-0de53d8956e8dcf80"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.main-subnet-public-01.id}"
  associate_public_ip_address = true
  key_name                    = "rakesh-ec2-east-1"
  user_data                   = "${data.template_file.template_blog.rendered}"

  //iam_instance_profile      = "yetToCreate" 
  vpc_security_group_ids = ["${aws_security_group.sg_80.id}"]

  tags = {
    Name = "blog"
  }
}
