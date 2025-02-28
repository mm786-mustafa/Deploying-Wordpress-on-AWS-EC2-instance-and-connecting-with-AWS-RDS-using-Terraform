variable "vpc_name" {
    description = "Name of the VPC"
    type = string
    default = "mustafa-vpc"
}

variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "igw_name" {
    description = "Name of internet gateway"
    type = string
    default = "mustafa-igw"
}

variable "ngw_name" {
    description = "Name of NAT gateway"
    type = string
    default = "mustafa-ngw"
}

variable "public_RT_name" {
    description = "Name of public route table"
    type = string
    default = "mustafa-public-RT"
}

variable "private_RT_name" {
    description = "Name of private route table"
    type = string
    default = "mustafa-private-RT"
}