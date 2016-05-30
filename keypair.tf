// Copyright (c) 2013 Kazumasa Kohtaka. All rights reserved.
// This file is available under the MIT license.

resource "aws_key_pair" "virtue_key_pair" {
  key_name = "virtue-key-pair"
  public_key = "${file(".ssh/id_rsa.pub")}"
}
