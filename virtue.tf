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
  default = "ap-northeast-1a,ap-northeast-1b"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_iam_role" "ecs_role" {
  name = "ecs-role"
  assume_role_policy = "${file("iam-policies/ecs-role.json")}"
}

resource "aws_iam_role_policy" "ecs_role_policy" {
  name = "ecs-role-policy"
  role = "${aws_iam_role.ecs_role.id}"
  policy = "${file("iam-policies/ecs-policy.json")}"
  depends_on = ["aws_iam_role.ecs_role"]
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

resource "aws_security_group" "web" {
  name = "web"
  description = "Allow inbound HTTP and HTTPS traffic"

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
  desired_count = 3
  iam_role = "${aws_iam_role.ecs_role.arn}"
  depends_on = [
    "aws_iam_role.ecs_role"
  ]

  load_balancer {
    elb_name = "${aws_elb.virtue_elb.name}"
    container_name = "prometheus"
    container_port = 9090
  }
}
