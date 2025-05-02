provider "aws" {
  region = "us-east-1"

}


data "aws_ami" "amazon_linux" {
  most_recent = true       # Selecciona la AMI más reciente que cumpla con los filtros
  owners      = ["amazon"] # Solo considera AMIs oficiales de Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # Coincide con el nombre de AMIs de Amazon Linux 2023 para 64 bits
  }


  filter {
    name   = "virtualization-type"
    values = ["hvm"] # Tipo compatible con t3.micro
  }
}


resource "aws_instance" "nginx-server" {
  ami           = data.aws_ami.amazo_linux.id
  instance_type = "t3.micro"

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx
              EOF



  vpc_security_group_ids = [
    aws_security_group.nginx-server-sg.id
  ]
  ## RESOURCES ASSOCIATE KEY( asociar llave) con otra resource
  key_name = aws_key_pair.ssh-key-nginx-server.key_name

  tags = {
    Name        = "nginx-server"
    Environment = "dev"
    Owner       = "Rodrigo"
    Team        = "DevOps"
    Projects    = "Ecommerce"

  }

}


resource "aws_key_pair" "ssh-key-nginx-server" {
  key_name   = "ssh-key-nginx-server"
  public_key = file("ssh-key-nginx-server.pub")
}

resource "aws_security_group" "nginx-server-sg" {
  name        = "nginx-server-sg"
  description = "Allow TLS inbound traffic"

  tags = {
    Name        = "nginx-server"
    Environment = "dev"
    Owner       = "Rodrigo"
    Team        = "DevOps"
    Projects    = "Ecommerce"

  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}
