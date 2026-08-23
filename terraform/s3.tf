# This block creates the storage container in the cloud to hold scripts
resource "aws_s3_bucket" "bootstrap" { # bootstrap is the nickname I chose for the s3 bucket
  bucket        = "s3-bootstrap-${random_id.bucket_suffix.hex}" # Must have random numbers to be unique
  force_destroy = true # important!, without this the terraform destroy would not be as effective and AWS will give out errors each deployment
  tags          = { Name = "s3-bootstrap-scripts" }
}

# Creates "randomness" for block above
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ------------------------------------------
# S3 OBJECT UPLOADS (Scripts & Configurations)
# ------------------------------------------
resource "aws_s3_object" "the_script" {
  bucket = aws_s3_bucket.bootstrap.id # Where to put file
  key    = "the_bootstrap.sh" # file name inside the s3 bucket
  source = "${path.module}/scripts/the_bootstrap.sh" # where is file in local computer
  etag   = filemd5("${path.module}/scripts/the_bootstrap.sh") # it calculates math hash (MD5) of lcal file
  # if you open script and change a single line and save, the hash changes, and when terraform apply is ran, it comparates hashes, realizes changes and uploads new version
}
