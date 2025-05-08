# Simple EC2 instance using the default VPC
resource "aws_instance" "test_instance" {
  ami           = "ami-0bc3fb9e5c6d8a138"
  instance_type = "m5.large"

  tags = {
    Name = "infracost-test"
  }
}
