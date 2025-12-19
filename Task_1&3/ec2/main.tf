locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hi, this is Jash's sample webapp $(hostname)</h1>" > /var/www/html/index.html
  EOF
}

resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "ec2_1" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_1_id
  availability_zone           = "ap-southeast-1a"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = "my-key"
  user_data                   = local.user_data

  tags = {
    Name = "JASH-EC2-1"
  }
}

resource "aws_instance" "ec2_2" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_2_id
  availability_zone           = "ap-southeast-1b"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = "my-key"
  user_data                   = local.user_data

  tags = {
    Name = "JASH-EC2-2"
  }
}


#Bastion_Host
########################################
# USER DATA
########################################
########################################
# SECURITY GROUPS
########################################

# Bastion Security Group
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "bastion-sg"
  }
}

# # Web EC2 Security Group
# resource "aws_security_group" "web_sg" {
#   name   = "web-sg"
#   vpc_id = var.vpc_id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port       = 22
#     to_port         = 22
#     protocol        = "tcp"
#     security_groups = [aws_security_group.bastion_sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "web-sg"
#   }
# }

# Private EC2 Security Group
resource "aws_security_group" "private_ec2_sg" {
  name   = "private-ec2-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ec2-sg"
  }
}

########################################
# EC2 INSTANCES
########################################

# Bastion Host (Public Subnet)
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_1_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = "my-key"

  tags = {
    Name = "Bastion-Host"
  }
}

# Web EC2 - AZ 1
resource "aws_instance" "web_ec2_1" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_1_id
  availability_zone           = "ap-southeast-1a"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = "my-key"
  user_data                   = local.user_data

  tags = {
    Name = "Web-EC2-1"
  }
}

# Web EC2 - AZ 2
resource "aws_instance" "web_ec2_2" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_2_id
  availability_zone           = "ap-southeast-1b"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = "my-key"
  user_data                   = local.user_data

  tags = {
    Name = "Web-EC2-2"
  }
}

# Private EC2
resource "aws_instance" "private_ec2" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = var.private_subnet_1
  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]
  key_name               = "my-key"

  tags = {
    Name = "Private-EC2"
  }
}
