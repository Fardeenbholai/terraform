resource "aws_instance" "first_instance" {
  ami = "ami-04d29b6f966df1537"
  instance_type = "t2.micro"
  user_data = "${file("userdata.sh")}"
}

output "instanceip" {
  value = aws_instance.first_instance.public_ip



}
