# This tells Terraform to build the infrastructure in the region set in the variables.tf file
# in this case, us-east-1 (N.Virginia) given that it was the default region for our location
provider "aws" {
    region = var.aws_region
}