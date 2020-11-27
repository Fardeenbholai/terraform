resource "aws_instance" "first_instance" {
  ami = "ami-04bf6dcdc9ab498ca"
  instance_type = "t2.micro"
}
// this is a new change 