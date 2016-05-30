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

resource "aws_iam_policy_attachment" "ecs_service_policy_attachment" {
    name = "ecs-service-policy-attachment"
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
