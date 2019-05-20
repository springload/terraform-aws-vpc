resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.vpc_name
    Tier = "public"
  }
}

resource "aws_route_table" "routes" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.vpc_name
    Tier = "public"
  }
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.routes.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "subnets" {
  count = local.subnets_count

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.cidr_block, 4, count.index + 10) # 10 subnets offset

  availability_zone       = element(data.aws_availability_zones.az.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name} ${substr(
      element(data.aws_availability_zones.az.names, count.index),
      -1,
      -1,
    )}"
    Tier = "public"
  }
}

resource "aws_route_table_association" "associations" {
  count = local.subnets_count

  subnet_id      = element(aws_subnet.subnets.*.id, count.index)
  route_table_id = aws_route_table.routes.id
}

# TIERED VPC STUFF
resource "aws_subnet" "private_subnets" {
  count = var.tiered ? local.subnets_count : 0

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.cidr_block, 4, count.index + 5) # 5 subnets offset

  availability_zone       = element(data.aws_availability_zones.az.names, count.index)
  map_public_ip_on_launch = ! (var.tiered_nat || var.tiered_multi_nat)

  tags = {
    Name = "${var.vpc_name} ${substr(
      element(data.aws_availability_zones.az.names, count.index),
      -1,
      -1,
    )} (private)"
    Tier = "private"
  }
}

# we use only one route table with one NAT
# or one route table per NAT if we have multiple
resource "aws_route_table" "private_routes_nat" {
  count = local.nat ? (var.tiered_multi_nat ? length(aws_subnet.private_subnets) : 1) : 0

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name} ${var.tiered_multi_nat ? substr(
      element(data.aws_availability_zones.az.names, count.index),
      -1,
      -1,
    ) : ""} (private)"
    Tier = "private"
  }
}

resource "aws_route_table_association" "private_associations" {
  count = length(aws_subnet.private_subnets)

  subnet_id = aws_subnet.private_subnets[count.index].id
  route_table_id = local.nat ? element(
    aws_route_table.private_routes_nat.*.id,
  count.index) : aws_route_table.routes.id
}


## NAT resources
resource "aws_eip" "eip" {
  count = local.nat ? (var.tiered_multi_nat ? length(aws_subnet.private_subnets) : 1) : 0

  vpc = true
}

resource "aws_nat_gateway" "nat" {
  count = local.nat ? (var.tiered_multi_nat ? length(aws_subnet.private_subnets) : 1) : 0

  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.private_subnets[count.index].id

  tags = {
    Name = "${var.vpc_name} ${substr(
      aws_subnet.private_subnets[count.index].availability_zone,
      -1,
      -1,
    )}"
    Tier = "private"
  }
}

# without multi use one nat for all subnets
resource "aws_route" "private_route_nat" {
  count = local.nat ? (var.tiered_multi_nat ? length(aws_subnet.private_subnets) : 1) : 0

  route_table_id         = element(aws_route_table.private_routes_nat.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)

}
