output "ec2_1_public_ip" {
  value = aws_instance.ec2_1.public_ip
}

output "ec2_2_public_ip" {
  value = aws_instance.ec2_2.public_ip
}

output "ec2_instance_ids" {
  value = [
    aws_instance.ec2_1.id,
    aws_instance.ec2_2.id
  ]
}
