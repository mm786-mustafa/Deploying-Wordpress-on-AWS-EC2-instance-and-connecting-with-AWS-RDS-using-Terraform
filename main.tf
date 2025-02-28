terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

data "aws_availability_zones" "available" {}

# *** VPC ***
resource "aws_vpc" "myVPC" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

# *** Internet Gateway ***
resource "aws_internet_gateway" "my_internet_gateway" {
  tags = {
    Name = var.igw_name
  }
}

# *** VPC Attachment***
resource "aws_internet_gateway_attachment" "internet_gateway_attachment" {
  vpc_id = aws_vpc.myVPC
  internet_gateway_id = aws_internet_gateway.my_internet_gateway
}

# *** Elastic IP Address ***
resource "aws_eip" "elastic_ip_address" {
  domain = "vpc"
}

# *** NAT Gateway ***
resource "aws_nat_gateway" "my_nat_gateway" {
  subnet_id = aws_subnet.MyPublicSubnet
  allocation_id = aws_eip.elastic_ip_address.allocation_id
  tags = {
    Name = var.ngw_name
  }
  
}

# *** Public Route Table ***
resource "aws_route_table" "my_public_route_table" {
  vpc_id = aws_vpc.myVPC
  tags = {
    Name = var.public_RT_name
  }
}

# *** Public Route ***
resource "aws_route" "public_route" {
  route_table_id = aws_route_table.my_public_route_table
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.my_internet_gateway
}

# *** Private Route Table ***
resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.myVPC
  tags = {
    Name = var.private_RT_name
  }
}

# *** Private Route ***
resource "aws_route" "private_route" {
  route_table_id = aws_route_table.my_private_route_table
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.my_nat_gateway
}

# *** Subnets ***
resource "aws_subnet" "MyPublicSubnet" {
  vpc_id = aws_vpc.myVPC
  count = length(data.aws_availability_zones.available.names)
  cidr_block = aws_vpc.myVPC.cidr_block
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "mustafa-public-subnet-1"
  }
}

# *** Public Subnet Route Table Association ***
resource "aws_route_table_association" "public_subnet_RT_association" {
  subnet_id = aws_subnet.MyPublicSubnet
  route_table_id = aws_route_table.my_public_route_table
}