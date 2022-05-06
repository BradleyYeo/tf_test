resource "aws_instance" "ec2_example" {
  ami                    = "ami-0bd6906508e74f692"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = "bradley_key"
  user_data              = file("aws-user-data.sh")

  tags = {
    Name = "tf-hello"
  }
}

resource "aws_security_group" "instance" {
  name = "tf-hello-instance"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
