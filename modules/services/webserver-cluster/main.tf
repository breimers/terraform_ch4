#put this state in s3
terraform{
  backend "s3"{
    bucket="terraform-ch3"
    key="~/terraform/ch3/stage/services/webserver-cluster/terraform.tfstate"
    region="us-east-2"
  }
}

#get data on remote state
data "terraform_remote_state" "db"{
	backend="s3"
	config{
		bucket="terraform-ch3"
    key="~/terraform/ch3/stage/datastores/mysql/terraform.tfstate"
    region="us-east-2"
	}
}
#get data on existing domain
data "aws_route53_zone" "selected"{
  name     = "bradsbox.info."
}
#get data on availability zones
data "aws_availability_zones" "all" {}
#template file data source
data "template_file" "user_data"{
	template = "${file("user-data.sh")}"
	vars{
		serverport = "${var.serverport}"
		db_address = "1.1.1.1/24"
		db_port    = "0000"
	}
}

#setup launch config for ec2 micro instances
resource "aws_launch_configuration" "ch2test" {
  image_id        = "ami-40d4f025"
  instance_type   ="t2.micro"
  security_groups =["${aws_security_group.instance.id}"]
  user_data       = "${data.template_file.user_data.rendered}" 
  lifecycle {
    create_before_destroy = true
  }
}

#provision ASG for webserver
resource "aws_autoscaling_group" "ch2test" {
  launch_configuration = "${aws_launch_configuration.ch2test.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  load_balancers       = ["${aws_elb.ch2test.name}"]
  health_check_type    = "ELB"
  min_size = 2
  max_size = 6
  tag {
    key                 = "Name"
    value               = "terraform-asg-ch2ex"
    propagate_at_launch = true
  }
}

#link dynamic instances with load balancer
resource "aws_elb" "ch2test" {
  name               = "terraform-asg-ch2ex"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.elb.id}"]
  #route traffic from listener port to instances
  listener {
    lb_port           = "${var.elbport}"
    lb_protocol       = "http"
    instance_port     = "${var.serverport}"
    instance_protocol = "http"
  }
  #perform a healthcheck and redirect traffic
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 60
    target              = "HTTP:${var.serverport}/"
  }
}

#accept all traffic from serverport
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress{
    from_port = "${var.serverport}"
    to_port   = "${var.serverport}"
    protocol  = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
  lifecycle{
    create_before_destroy = true
  }
}

#accept all traffic from elb port
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  ingress{
    from_port      = "${var.elbport}"
    to_port        = "${var.elbport}"
    protocol       = "tcp"
    cidr_blocks    =["0.0.0.0/0"]
  }
  egress{
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
