# ==========================================
# AUTHENTICATION: Cryptographic Key Pairs
# Description: Provisions the public SSH key required for secure, 
# passwordless access to the Linux-based EC2 instances.
# ==========================================

# PREREQUISITE: Generate the key pair locally before running 'terraform apply'
# Command: ssh-keygen -t rsa -b 4096 -f ~/.ssh/mostepic_key

# POST-DEPLOYMENT ACCESS:
# Command: ssh -i ~/.ssh/mostepic_key ubuntu@<brain_public_ip>

resource "aws_key_pair" "mostepic_key" {
    key_name   = "mostepic_key"
    public_key = file("~/.ssh/mostepic_key.pub")
}
