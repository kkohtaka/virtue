# Copyright (c) 2013 Kazumasa Kohtaka. All rights reserved.
# This file is available under the MIT license.

variable "aws_access_key" {
  type = "string"
  description = "AWS access key"
}

variable "aws_secret_key" {
  type = "string"
  description = "AWS secret key"
}

variable "aws_region" {
  type = "string"
  description = "AWS region"
  default = "ap-northeast-1"
}

variable "aws_availability_zones" {
  default = "string"
  description = ""
  default = "ap-northeast-1b,ap-northeast-1c"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_iam_role" "ecs_service_role" {
  name = "ecs-service-role"
  assume_role_policy = "${file("iam-policies/ecs-role.json")}"
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"
  assume_role_policy = "${file("iam-policies/ecs-role.json")}"
}

resource "aws_iam_policy_attachment" "ecs_policy_attachment" {
    name = "ecs-policy-attachment"
    roles = ["${aws_iam_role.ecs_service_role.name}"]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_policy_attachment" "ecs_instance_policy_attachment" {
    name = "ecs-instance-policy-attachment"
    roles = ["${aws_iam_role.ecs_instance_role.name}"]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "acs_instance_profile" {
  name = "ecs-instance-profile"
  roles = ["${aws_iam_role.ecs_instance_role.name}"]
  depends_on = [
    "aws_iam_policy_attachment.ecs_instance_policy_attachment"
  ]
}

resource "aws_key_pair" "virtue_key_pair" {
  key_name = "virtue-key-pair"
  public_key = "${file(".ssh/id_rsa.pub")}"
}

resource "aws_vpc" "virtue_vpc" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "virtue-vpc"
  }
}

resource "aws_subnet" "virtue_subnet_a" {
  vpc_id = "${aws_vpc.virtue_vpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "${element(split(",", var.aws_availability_zones), 0)}"
  tags {
    Name = "virtue-subnet-a"
  }
}

resource "aws_subnet" "virtue_subnet_b" {
  vpc_id = "${aws_vpc.virtue_vpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "${element(split(",", var.aws_availability_zones), 1)}"
  tags {
    Name = "virtue-subnet-b"
  }
}

resource "aws_internet_gateway" "virtue_gateway" {
  vpc_id = "${aws_vpc.virtue_vpc.id}"
  tags {
    Name = "virtue-gateway"
  }
}

resource "aws_route_table" "virtue_rtable" {
  vpc_id = "${aws_vpc.virtue_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.virtue_gateway.id}"
  }
  tags {
    Name = "virtue-rtable"
  }
}

resource "aws_route_table_association" "virtue_rtable_association_a" {
  subnet_id = "${aws_subnet.virtue_subnet_a.id}"
  route_table_id = "${aws_route_table.virtue_rtable.id}"
}

resource "aws_route_table_association" "virtue_rtable_association_b" {
  subnet_id = "${aws_subnet.virtue_subnet_b.id}"
  route_table_id = "${aws_route_table.virtue_rtable.id}"
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
  ingress {
    from_port = 443
    to_port = 443
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
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.virtue_vpc.id}"
  tags {
    Name = "web"
  }
}

resource "aws_instance" "ecs_instance_a" {
  //ami = "ami-72ae4313"
  ami = "ami-a98d97c7"
  instance_type = "t2.micro"
  key_name = "virtue-key-pair"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  subnet_id = "${aws_subnet.virtue_subnet_a.id}"
  //user_data = "${file("cloud-config/ecs-instance.yml")}"
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=virtue-cluster >> /etc/ecs/ecs.config
EOF
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.acs_instance_profile.name}"
  depends_on = [
    "aws_iam_instance_profile.acs_instance_profile"
  ]

  tags {
    Name = "ecs-instance"
  }
}

resource "aws_instance" "ecs_instance_b" {
  //ami = "ami-72ae4313"
  ami = "ami-a98d97c7"
  instance_type = "t2.micro"
  key_name = "virtue-key-pair"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  subnet_id = "${aws_subnet.virtue_subnet_b.id}"
  //user_data = "${file("cloud-config/ecs-instance.yml")}"
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=virtue-cluster >> /etc/ecs/ecs.config
EOF
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.acs_instance_profile.name}"
  depends_on = [
    "aws_iam_instance_profile.acs_instance_profile"
  ]

  tags {
    Name = "ecs-instance"
  }
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

resource "aws_ecs_cluster" "virtue_cluster" {
  name = "virtue-cluster"
}

resource "aws_ecs_task_definition" "prometheus_task" {
  family = "prometheus"
  container_definitions = "${file("task-definitions/prometheus.json")}"
}

resource "aws_ecs_service" "prometheus_service" {
  name = "prometheus-service"
  cluster = "${aws_ecs_cluster.virtue_cluster.id}"
  task_definition = "${aws_ecs_task_definition.prometheus_task.arn}"
  desired_count = 2
  iam_role = "${aws_iam_role.ecs_service_role.arn}"
  depends_on = [
    "aws_iam_policy_attachment.ecs_policy_attachment"
  ]
  load_balancer {
    elb_name = "${aws_elb.virtue_elb.name}"
    container_name = "prometheus"
    container_port = 9090
  }
}

output "ecs_instance_ip_a" {
  value = "${aws_instance.ecs_instance_a.public_ip}"
}

output "ecs_instance_ip_b" {
  value = "${aws_instance.ecs_instance_b.public_ip}"
}
