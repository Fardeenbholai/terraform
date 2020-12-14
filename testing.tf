resource "aws_instance" "first_instance" {
  ami = "ami-0fe2676b2d443f683"
  instance_type = "t2.micro"
  user_data = "${file("userdata.sh")}"
}

output "instanceip" {
  value = aws_instance.first_instance.public_ip



}
