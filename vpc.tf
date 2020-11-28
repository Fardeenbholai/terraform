resource "aws_vpc" "terraform_vpc" {
  cidr_block       = "${var.vpc_cidr}"
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