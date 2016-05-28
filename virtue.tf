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

resource "aws_iam_role" "virtue_role" {
  name = "virtue-role"
  assume_role_policy = "${file("iam-policies/sts-role.json")}"
}

resource "aws_iam_role_policy" "virtue_role_policy" {
  name = "virtue-role-policy"
  role = "${aws_iam_role.virtue_role.id}"
  policy = "${file("iam-policies/ecs-policy.json")}"
  depends_on = ["aws_iam_role.virtue_role"]
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
  iam_role = "${aws_iam_role.virtue_role.arn}"
  depends_on = [
    "aws_iam_role.virtue_role"
  ]

  load_balancer {
    elb_name = "${aws_elb.virtue_elb.name}"
    container_name = "prometheus"
    container_port = 9090
  }
}
