output "ec2_public_ip" {
  description = "Public IP address of EC2 instance"
  value       = aws_instance.pyflask_ec2.public_ip
}

output "instance_id" {
  description = "ID of EC2 instance"
  value       = aws_instance.pyflask_ec2.id
}

output "vpc_id" {
  description = "ID of custom Pyflask VPC"
  value       = aws_vpc.pyflask_vpc.id
}
