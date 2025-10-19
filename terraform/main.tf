resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "devops-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}a"
  tags = { Name = "public-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "pub_assoc" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "k3s_sg" {
  name = "k3s-sg"
  vpc_id = aws_vpc.this.id
  ingress {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }
  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }
  ingress {
    description = "Allow NodePort"
    from_port = 30000
    to_port = 32767
    protocol = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "k3s" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  key_name = aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  user_data = file("user_data/install_k3s.sh")
  tags = { Name = "k3s-node" }
}

resource "aws_ecr_repository" "frontend" {
  name = "employee-management-frontend"
}

resource "aws_ecr_repository" "backend" {
  name = "employee-management-backend"
}

output "k3s_public_ip" { value = aws_instance.k3s.public_ip }
output "ecr_frontend" { value = aws_ecr_repository.frontend.repository_url }
output "ecr_backend" { value = aws_ecr_repository.backend.repository_url }

