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

  provisioner "local-exec" { command = "aws ec2 wait instance-status-ok --instance-ids ${self.id} --region=us-east-1"}

  /*

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
    sudo cp -r ${path.module}/frontend .
    cd frontend
    sudo docker build -t ec2-frontend:v1.0 -f Dockerfile .
    sudo docker run -d -p 80:5173 ec2-frontend:v1.0
  EOF

  */

  tags = {
    Name = "TodoeyFrontend"
  }
}

resource "aws_instance" "td_backend" {
  depends_on = [aws_db_instance.postgres_server, aws_sns_topic.td_emails]
  ami           = "ami-0ebfd941bbafe70c6"
  instance_type = "t2.micro"
  key_name      = "cosc349-2024"

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_web.id,
    aws_security_group.allow_backend.id
  ]
  
  provisioner "local-exec" { command = "aws ec2 wait instance-status-ok --instance-ids ${self.id} --region=us-east-1" }

  /*
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
    sudo cp -r ${path.module}/backend .
    cd backend
    sudo docker build -t ec2-backend:v1.0 -f Dockerfile .
    sudo docker run -d -p 81:3000 ec2-backend:v1.0
  EOF
  */

  tags = {
    Name = "TodoeyBackend"
  }

}

resource "aws_sns_topic" "td_emails" {
  name = "td-emails-topic"
}

resource "aws_db_instance" "postgres_server" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t4g.micro"
  identifier           = "tdpostgresdb-instance"
  username             = "postgres"
  password             = "postgres"
  parameter_group_name = "default.postgres16"
  skip_final_snapshot  = true
  publicly_accessible  = true

  vpc_security_group_ids = [aws_security_group.allow_postgres_rds.id]

  tags = {
    Name = "PostgreSQLServer"
  }
}

resource "null_resource" "setup_db" {
  depends_on = [aws_db_instance.postgres_server]
  provisioner "local-exec" {
    environment = {
      PGPASSWORD = aws_db_instance.postgres_server.password
    }
    command = "psql -h ${aws_db_instance.postgres_server.address} -p 5432 -U ${aws_db_instance.postgres_server.username} -f ${path.module}/db/init.sql"
  }
}


resource "null_resource" "scp_frontend_files" {
  depends_on = [aws_instance.td_frontend]
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i /home/vagrant/cosc349-2024.pem -r ${path.module}/frontend ec2-user@${aws_instance.td_frontend.public_ip}:/home/ec2-user/"
  }

    provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.td_frontend.public_ip
      user        = "ec2-user"
      private_key = file("/home/vagrant/cosc349-2024.pem")
    }
    
    inline = [
      "sudo yum update -y && sudo yum install docker -y",
      "sudo systemctl start docker && sudo systemctl enable docker",

      /* This part will create .env files for frontend ec2 container, at the frontend container. */
      "echo VITE_EXPRESS_BACKEND_URL=http://${aws_instance.td_backend.public_ip}:81 > /home/ec2-user/frontend/.env",

      "cd frontend && sudo docker build -t ec2-frontend:v1.0 -f Dockerfile . && sudo docker run -d -p 80:5173 ec2-frontend:v1.0"
    ]
  }
}

resource "null_resource" "scp_backend_files" {
  depends_on = [aws_instance.td_backend]

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i /home/vagrant/cosc349-2024.pem -r ${path.module}/backend ec2-user@${aws_instance.td_backend.public_ip}:/home/ec2-user/"
  }

  #This block will copy credentials from vagrant to ec2_backend instance
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i /home/vagrant/cosc349-2024.pem /home/vagrant/.aws/credentials ec2-user@${aws_instance.td_backend.public_ip}:/home/ec2-user/backend/"
  }

    provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.td_backend.public_ip
      user        = "ec2-user"
      private_key = file("/home/vagrant/cosc349-2024.pem")
    }
    
    inline = [
      "sudo yum update -y && sudo yum install docker -y",
      "sudo systemctl start docker && sudo systemctl enable docker",

      /* This part will create .env files for backend ec2 container, at the backend container. */
      "echo PG_USER=${aws_db_instance.postgres_server.username} > /home/ec2-user/backend/.env",
      "echo PG_PASSWORD=${aws_db_instance.postgres_server.password} >> /home/ec2-user/backend/.env",
      "echo PG_HOST=${aws_db_instance.postgres_server.address} >> /home/ec2-user/backend/.env",
      "echo PG_PORT=5432 >> /home/ec2-user/backend/.env",
      "echo PG_DB=tdpostgresdb >> /home/ec2-user/backend/.env",
      "echo CORS_ORIGIN=http://${aws_instance.td_frontend.public_ip} >> /home/ec2-user/backend/.env",
      "echo PORT=3000 >> /home/ec2-user/backend/.env",
      "echo TOPIC_ARN=${aws_sns_topic.td_emails.arn} >> /home/ec2-user/backend/.env",
      "echo DIR_TO_AWS_CREDENTIALS=./credentials >> /home/ec2-user/backend/.env",

      "cd backend && sudo docker build -t ec2-backend:v1.0 -f Dockerfile . && sudo docker run -d -p 81:3000 ec2-backend:v1.0"
    ]
  }
}

output "todoey_frontend_ip" {
  value = aws_instance.td_frontend.public_ip
}

output "todoey_backend_ip" {
  value = "${aws_instance.td_backend.public_ip}:81"
}

output "postgres_server_ip" {
  value = aws_db_instance.postgres_server.address
}

output "sns_topic_arn" {
  value = aws_sns_topic.td_emails.arn
}
