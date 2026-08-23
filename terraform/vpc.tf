# Foundational Virtual Private Cloud (VPC)
resource "aws_vpc" "the_vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    tags = { Name = "the-VPC" }
}

resource "aws_subnet" "thesub_zone" {
    vpc_id     = aws_vpc.the_vpc.id
    cidr_block = "10.0.1.0/24"
    tags       = { Name = "thesub-Zone" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.the_vpc.id
  tags   = { Name = "the-IGW" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.the_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "the-Public-RT" }
}

# Associate both subnets so instances can reach the internet during bootstrap
resource "aws_route_table_association" "the_rta" {
  subnet_id      = aws_subnet.brain_zone.id
  route_table_id = aws_route_table.public_rt.id
}
