terraform {
  backend "s3" {
    bucket = "pyflask-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true // Enable state locking to prevent concurrent modifications
  }
}
