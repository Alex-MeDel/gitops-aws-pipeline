# The public IPv4 address
output "the_public_ip" {
  value       = aws_instance.the_instance.public_ip
  description = "SSH: ssh -i ~/.ssh/mostepic_key ubuntu@<this IP>"
}

# Debugging/Verification: Displays the dynamically selected Ubuntu AMI
output "ubuntu_ami_used" {
  value = data.aws_ami.ubuntu.id
  description = "The specific Ubuntu AMI ID provisioned for Linux instances"
}
