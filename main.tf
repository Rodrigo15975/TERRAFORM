
variable "SSH_KEY_FILE" {
  description = "SSH Key"
  default     = "ssh-key-nginx-server.pub"
  type        = string
}

variable "type_instace" {
  description = "Type Instance"
  default     = "t3.micro"
  type        = string
}

variable "environment" {
  description = "Environment"
  default     = "dev"
  type        = string

}

variable "server_name" {
  type        = string
  description = "Server name"
  default     = "nginx-server"
}

provider "aws" {
  region = "us-east-1"

}


data "aws_ami" "amazo_linux" {
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

  tags = {
    Name        = var.server_name
    Environment = var.environment
    Owner       = "Rodrigo"
    Team        = "DevOps"
    Projects    = "Ecommerce"
  }

}

### RESOURCE INSTANCE MAIN
### aws_instace es recurso de aws
### nginx-server es el identificador(o nombre)
resource "aws_instance" "nginx-server" {
  ami           = data.aws_ami.amazo_linux.id
  instance_type = var.type_instace

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx
              EOF


  ## RESOURCES ASSOCIATE SECURITY GROUP
  vpc_security_group_ids = [
    aws_security_group.nginx-server-sg.id
  ]
  ## RESOURCES ASSOCIATE KEY( asociar llave) con otra resource
  key_name = aws_key_pair.ssh-key-nginx-server.key_name

  ## RESOURCES ASSOCIATE TAG ( asociar etiquetas mejores practicas)
  tags = {
    Name        = var.server_name
    Environment = "dev"
    Owner       = "Rodrigo"
    Team        = "DevOps"
    Projects    = "Ecommerce"

  }

}


### RESOURCE KEY PAIR
resource "aws_key_pair" "ssh-key-nginx-server" {
  key_name   = "ssh-key-${var.server_name}"
  public_key = file(var.SSH_KEY_FILE)

  ## RESOURCES ASSOCIATE TAG ( asociar etiquetas mejores practicas)
  tags = {
    Name        = "${var.server_name}"
    Environment = "${var.environment}"
    Owner       = "Rodrigo"
    Team        = "DevOps"
    Projects    = "Ecommerce"

  }
}


### RESOURCE SECURITY GROUP
resource "aws_security_group" "nginx-server-sg" {
  name        = "${var.server_name}-sg"
  description = "Allow TLS inbound traffic"

  tags = {
    Name        = "${var.server_name}"
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

### OUTPUTS
output "server_public_ip" {
  description = "Public IP address of the EC2 instance"
  # ip de la instancia
  value = aws_instance.nginx-server.public_ip

}

### OUPUT-DNS
output "server_public_dns" {
  description = "Public DNS address of the EC2 instance"
  # dns de la instancia
  value = aws_instance.nginx-server.public_dns

}
