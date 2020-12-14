resource "aws_vpc" "terraform_vpc" {
  cidr_block = "${var.vpc_cidr}"
  tags = {
    Name = "terraformvpc"
  }
}

# creates an internet gateway inside terraformvpc
resource "aws_internet_gateway" "terra_igw" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  tags = {
    Name = "main"
  }
}

# subnets: public
resource "aws_subnet" "public" {
  count             = "${length(var.subnets_cidr_public)}"
  vpc_id            = "${aws_vpc.terraform_vpc.id}"
  cidr_block        = "${element(var.subnets_cidr_public, count.index)}"
  availability_zone = "${element(var.azs, count.index)}"
  tags = {
    "Name" = "Public-${count.index + 1}"
  }
}

# subnets : private
resource "aws_subnet" "private" {
  count             = "${length(var.subnets_cidr_private)}"
  vpc_id            = "${aws_vpc.terraform_vpc.id}"
  cidr_block        = "${element(var.subnets_cidr_private, count.index)}"
  availability_zone = "${element(var.azs, count.index)}"
  tags = {
    "Name" = "Private-${count.index + 1}"
  }
}

# eip for NAT gateway
resource "aws_eip" "nat" {
  count = "${length(var.subnets_cidr_public)}"
  vpc   = true

  # new replacement object is created first, and then the prior object is destroyed only once the replacement is created.
  lifecycle {
    create_before_destroy = true
  }
}

# NAT gateway
resource "aws_nat_gateway" "nat" {
  count         = "${length(var.subnets_cidr_public)}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element("${aws_subnet.public.*.id}", count.index)}"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "NAT-gateway public ${count.index + 1}"
  }
  depends_on = [aws_subnet.public, ]
}

# public route table: includes internet gateway
resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terra_igw.id}"
  }
  tags = {
    "Name" = "public rt"
  }
}

# private route table: includes route to NAT gateway

resource "aws_route_table" "private_rt" {
  count  = "${length(var.subnets_cidr_private)}"
  vpc_id = "${aws_vpc.terraform_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.nat.*.id, count.index)}"
  }
  tags = {
    "Name" = "private-rt ${count.index + 1}"
  }
}

# associate public route table with public subnet
resource "aws_route_table_association" "a-public" {
  count          = "${length(var.subnets_cidr_public)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

# associate private route table with private subnet
resource "aws_route_table_association" "a-private" {
  count          = "${length(var.subnets_cidr_public)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private_rt.*.id, count.index)}"
}

#security group 
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    description = "http from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

