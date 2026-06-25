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

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "pyflask-ec2-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -euxo pipefail

              # Docker installation
              dnf update -y
              dnf install -y docker
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user

              # Create system wide docker cli-plugins directory
              mkdir -p /usr/libexec/docker/cli-plugins

              # Download the latest Docker Compose plugin
              curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/libexec/docker/cli-plugins/docker-compose
              chmod +x /usr/libexec/docker/cli-plugins/docker-compose
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
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "pyflask-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
