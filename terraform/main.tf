provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "pyflask_ec2" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name

  # 1. Target custom subnet
  subnet_id = aws_subnet.pyflask_subnet.id

  # 2. switch to vpc_security_groups_ids and target SG's id
  vpc_security_group_ids = [aws_security_group.pyflask_sg.id]


  tags = {
    Name = "pyflask-ec2-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo systemctl start docker
              sudo usermod -aG docker ec2-user
              EOF
}

resource "aws_iam_role" "ec2_role" {
  name = "pyflask-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_attachment" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
}
