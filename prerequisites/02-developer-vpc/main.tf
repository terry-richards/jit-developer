data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "development_vpc" {
  cidr_block = "10.10.0.0/16"

  enable_dns_hostnames = true
  tags = {
    Name = "${var.namespace}-development-vpc"
  }
}

resource "aws_subnet" "development_subnet" {
  vpc_id            = aws_vpc.development_vpc.id
  cidr_block        = "10.10.0.0/16"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.namespace}-development-subnet-${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_internet_gateway" "development_ig" {
  vpc_id = aws_vpc.development_vpc.id

  tags = {
    Name = "${var.namespace}-development-ig"
  }
}

resource "aws_route" "main" {
  route_table_id         = aws_vpc.development_vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.development_ig.id
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.development_subnet.id
  route_table_id = aws_vpc.development_vpc.default_route_table_id
}

