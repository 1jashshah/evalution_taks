resource "aws_vpc" "jash-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Jash-VPC"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.jash-vpc.id

  tags = {
    Name = "jash-igw"
  }
}

resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.jash-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "public-rtb"
  }
}

resource "aws_subnet" "pub-sub-1" {
  vpc_id            = aws_vpc.jash-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "pub-sub-2" {
  vpc_id            = aws_vpc.jash-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
}

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.pub-sub-1.id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.pub-sub-2.id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_subnet" "pvt-sub-1" {
  vpc_id            = aws_vpc.jash-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "pvt-sub-2" {
  vpc_id            = aws_vpc.jash-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-southeast-1b"
}

resource "aws_eip" "eip-jash" {
  domain = "vpc"
}

resource "aws_nat_gateway" "my_nat_gw" {
  allocation_id = aws_eip.eip-jash.id
  subnet_id     = aws_subnet.pub-sub-1.id

  depends_on = [aws_internet_gateway.myigw]
}

resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.jash-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gw.id
  }
}

resource "aws_route_table_association" "pvt1" {
  subnet_id      = aws_subnet.pvt-sub-1.id
  route_table_id = aws_route_table.private-rtb.id
}

resource "aws_route_table_association" "pvt2" {
  subnet_id      = aws_subnet.pvt-sub-2.id
  route_table_id = aws_route_table.private-rtb.id
}
