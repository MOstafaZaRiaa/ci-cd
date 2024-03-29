terraform {
  backend "s3" {
    bucket = "statefile-eskam-storage"
    key    = "statefile"
    region = "us-east-1"
  }
}

provider "aws" {
  
  region  = "us-east-1"
}
variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.0.1.0/24"]
}
resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 tags = {
   Name = "Project VPC"
 }
}
resource "aws_subnet" "public_subnets" {
 count      = length(var.public_subnet_cidrs)
 vpc_id     = aws_vpc.main.id
 cidr_block = element(var.public_subnet_cidrs, count.index)
 tags = {
   Name = "Public Subnet ${count.index + 1}"
 }
}
resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
 tags = {
   Name = "Project VPC IG"
 }
}
resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.main.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 tags = {
   Name = "2nd Route Table"
 }
}
resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}
resource "aws_key_pair" "ubuntu" {
  key_name   = "ubuntu"
  public_key = var.PUB_KEY
}

resource "aws_security_group" "ubuntu" {
  name        = "ubuntu-security-group"
  description = "Allow HTTP, HTTPS and SSH traffic"
 vpc_id      = aws_vpc.main.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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


resource "aws_instance" "ubuntu" {
  key_name      = aws_key_pair.ubuntu.key_name
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t2.micro"
   subnet_id     = aws_subnet.public_subnets[0].id
   user_data = file("install.sh")

  tags = {
    Name = "ubuntu"
  }

  vpc_security_group_ids = [
    aws_security_group.ubuntu.id
  ]

 

  
}

resource "aws_eip" "ubuntu" {
  vpc      = true
  instance = aws_instance.ubuntu.id
}
output "ec2_ip"  {
  description = "Elastic ip address for Envoy nlb services"
  value       = aws_eip.ubuntu.public_ip
}
variable "PUB_KEY" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."
}

