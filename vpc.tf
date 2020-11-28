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
