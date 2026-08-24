# ==========================================
# AUTHENTICATION: Cryptographic Key Pairs
# Description: Provisions the public SSH key required for secure, 
# passwordless access to the Linux-based EC2 instances.
# ==========================================

# PREREQUISITE: Generate the key pair locally before running 'terraform apply'
# You can change the key name in variables.tf, default is mostepic_key
# Command: ssh-keygen -t rsa -b 4096 -f ~/.ssh/mostepic_key

# POST-DEPLOYMENT ACCESS:
# Command: ssh -i ~/.ssh/mostepic_key ubuntu@<the_public_ip>

resource "aws_key_pair" "the_key" {
    key_name   = var.key_name
    public_key = var.public_key
}
