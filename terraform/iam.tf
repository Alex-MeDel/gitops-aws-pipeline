# ==============================
# IAM permissions
# EC2 instances need IAM permission to read from the S3 bucket
# ==============================

resource "aws_iam_role" "ec2_bootstrap_role" {
  name = "the-ec2-bootstrap-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "s3_read" {
  name = "s3-bootstrap-read"
  role = aws_iam_role.ec2_bootstrap_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.bootstrap.arn}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "the-ec2-profile"
  role = aws_iam_role.ec2_bootstrap_role.name
}