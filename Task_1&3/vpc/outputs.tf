output "vpc_id" {
  value = aws_vpc.jash-vpc.id
}

output "private_subnet_1_cidr" {
  value = aws_subnet.pvt-sub-1.cidr_block
}

output "private_subnet_2_cidr" {
  value = aws_subnet.pvt-sub-2.cidr_block
}
output "public_subnet_1_id" {
  value = aws_subnet.pub-sub-1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.pub-sub-2.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.pub-sub-1.id,
    aws_subnet.pub-sub-2.id
  ]
}

output "private_subnet_1" {
  value = aws_subnet.pvt-sub-1
}



