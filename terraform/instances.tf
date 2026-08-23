resource "aws_instance" "the_instance" {
    ami                    = data.aws_ami.ubuntu.id # This is set in the data.tf, Dynamic AMI
    instance_type          = "t3.micro" # Instance type from AWS, 
    subnet_id              = aws_subnet.thesub_zone.id # Subnets created in vpc.tf
    vpc_security_group_ids = [aws_security_group.the_sg.id] # This is from security_groups.tf
    private_ip             = "10.0.2.10" # Just sets static IP for this particular device
    key_name               = aws_key_pair.mostepic_key.key_name  # This is part of SSH config
    associate_public_ip_address = true   # This line will give the instance access to a public IP address for bootstraping
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name # IAM things
    tags                   = { Name = "The-Instance" } # This is for billing info


    # CONFIGURE EVERYTHING ON STARTUP!!!
    # Passes the dynamic S3 bucket ID to the bash script
    user_data = templatefile("${path.module}/scripts/the_bootstrap.sh", {
      bucket_name = aws_s3_bucket.bootstrap.id # This is configured in s3.tf
    })
}