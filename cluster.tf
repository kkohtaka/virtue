# Copyright (c) 2013 Kazumasa Kohtaka. All rights reserved.
# This file is available under the MIT license.

variable "aws_availability_zones" {
  default = "string"
  description = ""
  default = "ap-northeast-1b,ap-northeast-1c"
}

resource "aws_ecs_cluster" "virtue_cluster" {
  name = "virtue-cluster"
}

resource "aws_elb" "virtue_elb" {
  name = "virtue-elb"
  availability_zones = ["${split(",", var.aws_availability_zones)}"]
  listener {
    instance_port = 9090
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }
}

resource "aws_security_group" "web" {
  name = "web"
  description = "Allow inbound HTTP and HTTPS traffic"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.virtue_vpc.id}"
  tags {
    Name = "web"
  }
  depends_on = [
    "aws_key_pair.virtue_key_pair"
  ]
}

resource "aws_instance" "virtue_instance_a" {
  ami = "ami-a98d97c7"
  instance_type = "t2.micro"
  key_name = "virtue-key-pair"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  subnet_id = "${aws_subnet.virtue_subnet_a.id}"
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=virtue-cluster >> /etc/ecs/ecs.config
EOF
  associate_public_ip_address = true
  iam_instance_profile = "ecs-instance-role"
  tags {
    Name = "ecs-instance"
  }
  depends_on = [
    "aws_key_pair.virtue_key_pair",
    "aws_ecs_cluster.virtue_cluster"
  ]
}

resource "aws_instance" "virtue_instance_b" {
  ami = "ami-a98d97c7"
  instance_type = "t2.micro"
  key_name = "virtue-key-pair"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  subnet_id = "${aws_subnet.virtue_subnet_b.id}"
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=virtue-cluster >> /etc/ecs/ecs.config
EOF
  associate_public_ip_address = true
  iam_instance_profile = "ecs-instance-role"
  tags {
    Name = "ecs-instance"
  }
  depends_on = [
    "aws_key_pair.virtue_key_pair",
    "aws_ecs_cluster.virtue_cluster"
  ]
}

output "virtue_elb_dns_name" {
  value = "${aws_elb.virtue_elb.dns_name}"
}

output "virtue_instance_ip_a" {
  value = "${aws_instance.virtue_instance_a.public_ip}"
}

output "virtue_instance_ip_b" {
  value = "${aws_instance.virtue_instance_b.public_ip}"
}
