resource "aws_vpc" "pyflask_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "pyflask_subnet" {
  vpc_id                  = aws_vpc.pyflask_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = var.aws_availability_zone # force the subnet to be created in a specific AZ
}

resource "aws_internet_gateway" "pyflask_igw" {
  vpc_id = aws_vpc.pyflask_vpc.id
}

resource "aws_route_table" "pyflask_rt" {
  vpc_id = aws_vpc.pyflask_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pyflask_igw.id
  }
}

resource "aws_route_table_association" "pyflask_rta" {
  subnet_id      = aws_subnet.pyflask_subnet.id
  route_table_id = aws_route_table.pyflask_rt.id
}
