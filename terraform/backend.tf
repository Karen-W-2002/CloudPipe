terraform {
  backend "s3" {
    bucket = "pyflask-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
