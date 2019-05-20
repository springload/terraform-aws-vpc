variable "cidr_block" {}
variable "vpc_name" {}


variable "tiered" {
  default = true
}

variable "tiered_nat" {
  default = false
}

variable "tiered_multi_nat" {
  default = false
}

locals {
  subnets_count = "${length(data.aws_availability_zones.az.names)}"
  nat           = var.tiered_nat || var.tiered_multi_nat
}
