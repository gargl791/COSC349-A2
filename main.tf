provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH traffic"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow inbound HTTP(S) traffic"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "allow_backend" {
  name        = "allow_backend"
  description = "Give backend a neighbor ec2 instance port from HTTP"

  ingress {
    description = "Allow inbound traffic for backend"
    from_port   = 81
    to_port     = 81
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

resource "aws_security_group" "allow_postgres_rds" {
  name        = "allow_postgres_rds"
  description = "Allow inbound PostgreSQL traffic"

  ingress {
    description = "PostgreSQL from anywhere"
    from_port   = 5432
    to_port     = 5432
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

resource "aws_instance" "td_frontend" {
  ami           = "ami-0ebfd941bbafe70c6"
  instance_type = "t2.micro"
  key_name      = "cosc349-2024"

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_web.id
  ]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
  EOF

  tags = {
    Name = "TodoeyFrontend"
  }
}

resource "aws_instance" "td_backend" {
  ami           = "ami-0ebfd941bbafe70c6"
  instance_type = "t2.micro"
  key_name      = "cosc349-2024"

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_web.id,
    aws_security_group.allow_backend.id
  ]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
  EOF

  tags = {
    Name = "TodoeyBackend"
  }
}

resource "aws_db_instance" "postgres_server" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t4g.micro"
  name                 = "tdpostgres"
  username             = "postgres"
  password             = "postgres"
  parameter_group_name = "default.postgres16"
  skip_final_snapshot  = true
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.allow_postgres_rds.id]
}

output "todoey_frontend_ip" {
  value = aws_instance.td_frontend.public_ip
}

output "todoey_backend_ip" {
  value = aws_instance.td_backend.public_ip
}

output "postgres_server_ip" {
  value = aws_instance.postgres_server.public_ip
}