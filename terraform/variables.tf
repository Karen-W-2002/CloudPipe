variable "ec2_instance_type" {
  default = "t3.micro"
}

variable "ec2_ami" {
  default = "ami-00e801948462f718a"
}

# this is the keypair name
variable "ec2_key_name" {
  default = "karen-ec2-key"
}

variable "aws_region" {
  default = "us-east-1"
}
