// Copyright (c) 2013 Kazumasa Kohtaka. All rights reserved.
// This file is available under the MIT license.

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
