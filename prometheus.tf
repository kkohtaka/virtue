// Copyright (c) 2013 Kazumasa Kohtaka. All rights reserved.
// This file is available under the MIT license.

resource "aws_elb" "prometheus_elb" {
  name = "prometheus-elb"
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

resource "aws_ecs_task_definition" "prometheus_task" {
  family = "prometheus"
  container_definitions = "${file("task-definitions/prometheus.json")}"
}

resource "aws_ecs_service" "prometheus_service" {
  name = "prometheus-service"
  cluster = "${aws_ecs_cluster.virtue_cluster.id}"
  task_definition = "${aws_ecs_task_definition.prometheus_task.arn}"
  desired_count = 2
  iam_role = "ecs-service-role"
  load_balancer {
    elb_name = "${aws_elb.prometheus_elb.name}"
    container_name = "prometheus"
    container_port = 80
  }
  depends_on = [
    "aws_instance.virtue_instance_a",
    "aws_instance.virtue_instance_b"
  ]
}

output "prometheus_elb_dns_name" {
  value = "${aws_elb.prometheus_elb.dns_name}"
}
