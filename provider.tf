// Copyright (c) 2013 Kazumasa Kohtaka. All rights reserved.
// This file is available under the MIT license.

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

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}
