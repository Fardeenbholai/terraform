resource "aws_vpc" "terraform_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "terraformvpc"
  }
}

# creates an internet gateway inside terraformvpc
resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "main"
  }
}

# subnets: public
resource "aws_subnet" "public" {
  count             = length(var.subnets_cidr_public)
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = element(var.subnets_cidr_public, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    "Name" = "Public-${count.index + 1}"
  }
}

# subnets : private
resource "aws_subnet" "private" {
  count             = length(var.subnets_cidr_private)
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = element(var.subnets_cidr_private, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    "Name" = "Private-${count.index + 1}"
  }
}

# eip for NAT gateway
resource "aws_eip" "nat" {
  count = length(var.subnets_cidr_public)
  vpc   = true

  # new replacement object is created first, and then the prior object is destroyed only once the replacement is created.
  lifecycle {
    create_before_destroy = true
  }
}

# NAT gateway
resource "aws_nat_gateway" "nat" {
  count         = length(var.subnets_cidr_public)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element("${aws_subnet.public.*.id}", count.index)

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
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_igw.id
  }
  tags = {
    "Name" = "public rt"
  }
}

# private route table: includes route to NAT gateway

resource "aws_route_table" "private_rt" {
  count  = length(var.subnets_cidr_private)
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)
  }
  tags = {
    "Name" = "private-rt ${count.index + 1}"
  }
}

# associate public route table with public subnet
resource "aws_route_table_association" "a-public" {
  count          = length(var.subnets_cidr_public)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

# associate private route table with private subnet
resource "aws_route_table_association" "a-private" {
  count          = length(var.subnets_cidr_public)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private_rt.*.id, count.index)
}

# Create a new load balancer
# module "alb" {
#   source  = "terraform-aws-modules/alb/aws"
#   version = "~> 5.0"

#   name = "my-alb"

#   load_balancer_type = "application"
#   vpc_id             = aws_vpc.terraform_vpc.id
#   subnets            = ["subnet-abcde012", "subnet-bcde012a"]
#   security_groups    = ["sg-edcd9784", "sg-edcd9785"]
# }

# create security group for alb


resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "allow http traffic to ELB"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    description = "http from outside AWS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

# create a load balancer
resource "aws_lb" "alb" {
  name               = "development-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = aws_subnet.public.*.id

  tags = {
    Environment = "development"
  }
  depends_on = [aws_security_group.allow_http, aws_lb_target_group.alb_tg, ]
}

# create load balancer target group
resource "aws_lb_target_group" "alb_tg" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_vpc.id
}

# create a load balancer listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

# Create a launch configuration for the autoscaling group
resource "aws_launch_configuration" "asg_lt" {
  image_id        = "${file("ami.json")}" # build with Packer
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.allow_http.id]
  depends_on      = [aws_security_group.allow_http, ]
}

# Create an auto scaling group
resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 1
  max_size             = 4
  min_size             = 1
  launch_configuration = aws_launch_configuration.asg_lt.name
  health_check_type    = "ELB"
  vpc_zone_identifier  = aws_subnet.private.*.id
  depends_on           = [aws_launch_configuration.asg_lt, ]
}

# Create a new load balancer attachment
resource "aws_autoscaling_attachment" "asg_attachment_alb" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  alb_target_group_arn   = aws_lb_target_group.alb_tg.arn
}
