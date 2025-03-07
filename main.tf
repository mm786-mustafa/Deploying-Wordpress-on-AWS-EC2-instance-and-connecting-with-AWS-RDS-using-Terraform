terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.89.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  Environment = {
    "dev" = "t2.micro"
    "testing" = "t2.micro"
    "prod" = "t2.micro"
  }
}

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

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
  vpc_id = aws_vpc.myVPC.id
  internet_gateway_id = aws_internet_gateway.my_internet_gateway.id
}

# *** Elastic IP Address ***
resource "aws_eip" "elastic_ip_address" {
  domain = "vpc"
}

# *** NAT Gateway ***
resource "aws_nat_gateway" "my_nat_gateway" {
  subnet_id = aws_subnet.creating_public_subnets[0].id
  allocation_id = aws_eip.elastic_ip_address.allocation_id
  tags = {
    Name = var.ngw_name
  }
  depends_on = [ aws_internet_gateway.my_internet_gateway ]
}

# *** Public Route Table ***
resource "aws_route_table" "my_public_route_table" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    Name = var.public_RT_name
  }
}

# *** Public Route ***
resource "aws_route" "public_route" {
  route_table_id = aws_route_table.my_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.my_internet_gateway.id
}

# *** Private Route Table ***
resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    Name = var.private_RT_name
  }
}

# *** Private Route ***
resource "aws_route" "private_route" {
  route_table_id = aws_route_table.my_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.my_nat_gateway.id
}

# *** Public Subnets ***
resource "aws_subnet" "creating_public_subnets" {
  vpc_id = aws_vpc.myVPC.id
  count = length(data.aws_availability_zones.available.names)
  cidr_block = cidrsubnet(var.vpc_cidr, var.subnet_mask, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.public_subnet_name}-${count.index+1}-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# *** Public Subnet Route Table Association ***
resource "aws_route_table_association" "public_subnet_RT_association" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id = aws_subnet.creating_public_subnets[count.index].id
  route_table_id = aws_route_table.my_public_route_table.id
}

# *** Private Subnets ***
resource "aws_subnet" "creating_private_subnets" {
  vpc_id = aws_vpc.myVPC.id
  count = length(data.aws_availability_zones.available.names)
  cidr_block = cidrsubnet(var.vpc_cidr, var.subnet_mask, count.index+2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.private_subnet_name}-${count.index+1}-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# *** Private Subnet Route Table Association ***
resource "aws_route_table_association" "private_subnet_RT_association" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id = aws_subnet.creating_private_subnets[count.index].id
  route_table_id = aws_route_table.my_private_route_table.id
}

# *** Security Group ***
resource "aws_security_group" "my_security_group" {
  vpc_id = aws_vpc.myVPC.id
  description = "Allow HTTP and MySQL access"
  tags = {
    Name = "${var.security_group_name}-${data.aws_region.current.name}"
  }
}

# *** Security Group Inbound Rule ***
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.my_security_group.id
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = "0.0.0.0/0"
}

# *** Security Group Inbound Rule ***
resource "aws_vpc_security_group_ingress_rule" "allow_mysql" {
  security_group_id = aws_security_group.my_security_group.id
  ip_protocol = "tcp"
  from_port = 3306
  to_port = 3306
  cidr_ipv4 = aws_subnet.creating_private_subnets[0].cidr_block
}

# *** RDS Database ***
resource "aws_db_instance" "my_rds_database" {
  allocated_storage = 20
  identifier = var.rds_instance_identifier
  db_name = var.db_name
  engine = "mysql"
  engine_version = "8.0.33"
  storage_type = "gp3"
  instance_class = "db.t3.micro"
  username = var.db_username
  password = var.db_password
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.id
  vpc_security_group_ids = [ aws_security_group.my_security_group.id ]
  skip_final_snapshot = true
}

# *** DB Subnet Group for RDS ***
resource "aws_db_subnet_group" "my_db_subnet_group" {
  description = "Subnet group for RDS"
  subnet_ids = [ aws_subnet.creating_private_subnets[0].id, aws_subnet.creating_private_subnets[1].id ]
}

# *** EC2 Instance ***
resource "aws_instance" "my_ec2_instance" {
  instance_type = "t2.micro"
  ami = "ami-018a1ea25ff5268f0"
  key_name = "mustafa-california-key"
  subnet_id = aws_subnet.creating_private_subnets[0].id
  security_groups = [ aws_security_group.my_security_group.id ]
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install php7.4 -y
    sudo yum install httpd -y
    sudo yum install mysql -y
    sudo yum install php-mysqlnd php-fpm php-json php-xml php-gd php-mbstring -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    wget https://wordpress.org/latest.tar.gz
    tar -xvzf latest.tar.gz
    sudo mv wordpress/* /var/www/html/
    sudo chown -R apache:apache /var/www/html/
    sudo systemctl restart httpd
    sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sudo sed -i "s/database_name_here/${var.db_name}/" /var/www/html/wp-config.php
    sudo sed -i "s/username_here/${var.db_username}/" /var/www/html/wp-config.php
    sudo sed -i "s/password_here/${var.db_password}/" /var/www/html/wp-config.php
    sudo sed -i "s/localhost/${split(":",aws_db_instance.my_rds_database.endpoint)[0]}/" /var/www/html/wp-config.php
    sudo systemctl restart httpd
    EOF
    # "${file("user_data.sh")}"
  tags = {
    Name = "${var.my_ec2_instance_name}-${data.aws_region.current.name}"
  }
}

# *** Target Group for Load Balancer ***
resource "aws_lb_target_group" "my_target_group" {
  name = var.target_group_name
  target_type = "instance"
  protocol = "HTTP"
  port = 80
  vpc_id = aws_vpc.myVPC.id
  health_check {
    path = "/wp-admin/install.php"
  }
}

# *** Target Group Attachment **
resource "aws_lb_target_group_attachment" "target_group_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id = aws_instance.my_ec2_instance.id
  port = 80
}

# *** Application Load Balancer ***
resource "aws_alb" "my_alb" {
  load_balancer_type = "application"
  name = var.lb_name
  ip_address_type = "ipv4"
  security_groups = [ aws_security_group.my_security_group.id ]
  subnets = [ aws_subnet.creating_public_subnets[0].id, aws_subnet.creating_public_subnets[1].id ]
}

# *** ALB Listener ***
resource "aws_alb_listener" "my_alb_listener" {
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
  load_balancer_arn = aws_alb.my_alb.arn
  port = 80
  protocol = "HTTP"
}