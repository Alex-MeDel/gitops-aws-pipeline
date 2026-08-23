#!/bin/bash

set -e  # Exit immediately if any command fails for debugging

# Redirect all stdout and stderr to a log file for deployment debugging
exec > /var/log/the_bootstrap.log 2>&1  # Log everything
echo "=== The Bootstrap Starting ==="


# ---------------------------------------------------
# 2. Package Installation: Docker & AWS CLI
# ---------------------------------------------------
echo "Installing dependencies..."
apt-get update -y
apt-get install -y docker.io docker-compose awscli
systemctl enable docker
systemctl start docker

# ---------------------------------------------------
# 3. Secure Asset Retrieval
# ---------------------------------------------------
# BUCKET_NAME is dynamically injected by Terraform's templatefile() function.
echo "Pulling configuration assets from S3..."

# This pulls files from the S3 bucket, example for docker
# aws s3 cp s3://${bucket_name}/docker-compose.yml     /home/ubuntu/docker-compose.yml

# Fix ownership so ubuntu user can interact with the files (No Sudo for everything)
chown -R ubuntu:ubuntu /home/ubuntu

# ---------------------------------------------------
# 4. Container Orchestration 
# ---------------------------------------------------
#echo "Starting Docker Compose..."
#cd /home/ubuntu
#docker-compose up -d

#echo "=== The Bootstrap Complete ==="
