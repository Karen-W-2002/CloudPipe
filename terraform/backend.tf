terraform {
    backend "s3" {
	bucket = "pyflask-tfstate"
	key = "terraform.tfstate"
	region = var.aws_region
    }
}
