variable "cidr_block" {
  description = "CIDR block of the new VPC"
}

variable "vpc_name" {
  description = "VPC name"
}

variable "subnet_offset" {
  description = "Offset for subnets within a range"
  type = number
}
variable "tiered" {
  description = "Create tiered subnet configuration: private/public subnets"
  default     = true
}

variable "tiered_nat" {
  description = "Create one NAT instance for all private subnets"
  default     = false
}

variable "tiered_multi_nat" {
  description = "Create multiple NAT instances (one per private subnet)"
  default     = false
}

locals {
  subnets_count = "${length(data.aws_availability_zones.az.names)}"
  nat           = var.tiered_nat || var.tiered_multi_nat
}
