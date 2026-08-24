provider "aws" {
    region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "my-gitops-tf-state-5198121"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}