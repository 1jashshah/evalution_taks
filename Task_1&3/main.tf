provider "aws" {
  region = "ap-southeast-1"
}

module "vpc" {
  source = "./vpc"
}

module "ec2" {
  source = "./ec2"

  vpc_id              = module.vpc.vpc_id
  public_subnet_1_id  = module.vpc.public_subnet_1_id
  public_subnet_2_id  = module.vpc.public_subnet_2_id
  private_subnet_1    = module.vpc.private_subnet_1.id
}

module "alb" {
  source = "./alb"

  vpc_id = module.vpc.vpc_id

  public_subnet_ids = [
    module.vpc.public_subnet_1_id,
    module.vpc.public_subnet_2_id
  ]

  instance_ids = module.ec2.ec2_instance_ids
}

module "asg" {
  source = "./asg"

  ami_id        = "ami-05f071c65e32875a8"
  instance_type = "t2.micro"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_group_arns = [module.alb.target_group_arn]
}
