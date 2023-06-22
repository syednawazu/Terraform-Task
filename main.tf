provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "My-VPC" {
  cidr_block       = "192.168.0.0/16"
  
  tags = {
    Name = "Nawaz-VPC"
  }
}
# Create Internet gateway
resource "aws_internet_gateway" "My-igw" {
  vpc_id = aws_vpc.My-VPC.id

    tags = {
    Name = "Nawaz-IGW"
  }
}


# Create Custom Route Table
resource "aws_route_table" "My-Route_Table" {
  vpc_id = aws_vpc.My-VPC.id
 
 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.My-igw.id
  }
  tags = {
    Name = "Nawaz-RT"
  }
}
# Create Subnet
resource "aws_subnet" "My-subnet" {
  vpc_id = aws_vpc.My-VPC.id
  cidr_block = "192.168.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Nawaz-Subnet"
  }
}
# Associate subnet with Route Table
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.My-subnet.id
  route_table_id = aws_route_table.My-Route_Table.id
}

# Create Security Group to allow port 22.80,443
resource "aws_security_group" "my_security_group" {
  name        = "Nawaz-security-group"
  description = "Allow SSH, HTTP, and HTTPS traffic"

  # Ingress rule for SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule for HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule for HTTPS (port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule (allow all traffic outbound)
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Attach the security group to the VPC
  vpc_id = aws_vpc.My-VPC.id
}


# Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "my_network_interface" {
  subnet_id       = aws_subnet.My-subnet.id
  private_ips     = ["192.168.0.24"]  
  security_groups = [aws_security_group.my_security_group.id]

  tags = {
    Name = "Nawaz-network-interface"
  }
}
# Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "example" {
  vpc = true
  network_interface = aws_network_interface.my_network_interface.id

  tags = {
    Name = "Nawaz-EIP"
  }
}

# Create Ubuntu server and install/enable apache2
resource "aws_instance" "my_instance" {
  ami                    = "ami-0261755bbcb8c4a84"  
  instance_type          = "t2.micro"  
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  key_name               = "Nawaz-Server"  
  subnet_id              = aws_subnet.My-subnet.id 
  associate_public_ip_address = true  
  
  tags = {
    Name = "Nawaz-Ubuntu-Server"
  }
user_data = <<-EOF
      #!/bin/bash 
      sudo apt-get update
      sudo apt-get install apache2 -y
      sudo systemctl enable apache2
      sudo systemctl start apache2
  EOF
}