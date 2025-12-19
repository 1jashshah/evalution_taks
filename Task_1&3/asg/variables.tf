variable "ami_id" {
  description = "AMI ID for EC2"
  type        = string
}

variable "instance_type" {
  description = "Instance type for ASG"
  type        = string
  default     = "t2.micro"
}

variable "subnet_ids" {
  description = "Public subnet IDs where ASG will launch instances"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "target_group_arns" {
  description = "List of Target Group ARNs for ALB"
  type        = list(string)
  default     = []
}
