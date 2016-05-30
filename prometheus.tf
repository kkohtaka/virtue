// Copyright (c) 2013 Kazumasa Kohtaka. All rights reserved.
// This file is available under the MIT license.

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
    elb_name = "${aws_elb.virtue_elb.name}"
    container_name = "prometheus"
    container_port = 9090
  }
  depends_on = [
    "aws_instance.virtue_instance_a",
    "aws_instance.virtue_instance_b"
  ]
}
