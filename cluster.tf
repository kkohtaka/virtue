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

resource "aws_launch_configuration" "virtue_launch_configuration" {
  name = "virtue-launch-configuration"
  image_id = "ami-a98d97c7"
  instance_type = "t2.micro"
  iam_instance_profile = "ecs-instance-role"
  key_name = "virtue-key-pair"
  security_groups = ["${aws_security_group.web.id}"]
  associate_public_ip_address = true
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=virtue-cluster >> /etc/ecs/ecs.config
EOF
  depends_on = [
    "aws_key_pair.virtue_key_pair"
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "virtue_autoscaling_group" {
  name = "virtue-autoscaling-group"
  max_size = 2
  min_size = 2
  launch_configuration = "${aws_launch_configuration.virtue_launch_configuration.id}"
  health_check_type = "EC2"
  vpc_zone_identifier = [
    "${aws_subnet.virtue_subnet_a.id}",
    "${aws_subnet.virtue_subnet_b.id}"
  ]
  depends_on = [
    "aws_internet_gateway.virtue_gateway",
    "aws_route_table_association.virtue_rtable_association_a",
    "aws_route_table_association.virtue_rtable_association_b"
  ]
  lifecycle {
    create_before_destroy = true
  }
}
