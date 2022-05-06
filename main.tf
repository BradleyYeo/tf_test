resource "aws_vpc" "main" {
  cidr_block = "10.11.0.0/16"
  tags = {
    Name = "BradleyTfVpc"
  }
}

resource "aws_subnet" "subN1" {
  vpc_id            = "vpc-06650a004943f5928"
  cidr_block        = "10.10.0.0/24"
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "subnetCB1"
  }
}
resource "aws_subnet" "subN2" {
  vpc_id     = "vpc-06650a004943f5928"
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-southeast-1b"
  tags = {
    Name = "subnetCB2"
  }
}
resource "aws_route_table_association" "route_table_assoc" {
  subnet_id      = "subnet-05408e78b2d44edcf" 
  route_table_id = "rtb-0ab00222cee9aaf6a" 
}

resource "aws_route_table_association" "route_table_assoc2" {
  subnet_id      = "subnet-075a6033b4c48cebe" 
  route_table_id = "rtb-0ab00222cee9aaf6a" 
}
