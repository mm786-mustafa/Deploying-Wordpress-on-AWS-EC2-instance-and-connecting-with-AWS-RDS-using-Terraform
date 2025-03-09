variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  description = "Environment in which infrastructure is being created."
  type = string
  default = "dev"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance."
  type = string
  default = "t2.micro"
}

variable "ami" {
  description = "Also known as image id."
  type = string
  default = "ami-018a1ea25ff5268f0"
}

variable "key_name" {
  description = "Key for remote access."
  type = string
  default = "mustafa-california-key"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "mustafa-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "igw_name" {
  description = "Name of internet gateway"
  type        = string
  default     = "mustafa-igw"
}

variable "eip_name" {
  description = "Name of elastic IP"
  type = string
  default = "mustafa-eip"
}

variable "ngw_name" {
  description = "Name of NAT gateway"
  type        = string
  default     = "mustafa-ngw"
}

variable "public_RT_name" {
  description = "Name of public route table"
  type        = string
  default     = "mustafa-public-RT"
}

variable "private_RT_name" {
  description = "Name of private route table"
  type        = string
  default     = "mustafa-private-RT"
}

variable "public_subnet_name" {
  description = "Name of public subnet"
  type        = string
  default     = "mustafa-public-subnet"
}

variable "private_subnet_name" {
  description = "Name of private subnet"
  type        = string
  default     = "mustafa-private-subnet"
}

variable "subnet_mask" {
  description = "Subnet Mask"
  type        = string
  default     = 8
}

variable "security_group_name" {
  description = "Name of security game"
  type        = string
  default     = "mustafa-sg"
}

variable "rds_instance_identifier" {
  description = "Instance identifier"
  type = string
  default = "mustafa-db"
}

variable "db_name" {
  description = "Database name"
  type = string
  default = "wordpress"
}

variable "db_username" {
  description = "Database username"
  type = string
  default = "m_mustafa"
}

variable "db_password" {
  description = "Database password"
  type = string
  default = "no1knows786"
}

variable "my_ec2_instance_name" {
  description = "Name of EC2 Instance"
  type = string
  default = "mustafa-ec2-instance"
}

variable "target_group_name" {
  description = "Target group name"
  type = string
  default = "mustafa-tg"
}

variable "lb_name" {
  description = "Name of load balancer"
  type = string
  default = "mustafa-LB"
}