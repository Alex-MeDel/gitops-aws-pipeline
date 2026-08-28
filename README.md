# Full-Stack GitOps Deployment on AWS

This repository contains a fully automated GitOps pipeline that provisions AWS infrastructure, configures the host environment, and deploys a containerized microservices application entirely through GitHub Actions.

The project demonstrates Infrastructure as Code (IaC), Configuration Management, and Zero-Trust CI/CD deployment principles.

## 🚀 Architecture & Technologies

### 1. CI/CD & Automation (GitHub Actions)
* **Zero-Trust Authentication:** Utilizes AWS OIDC (OpenID Connect) for authentication, eliminating the need for long-lived, hardcoded AWS IAM user credentials.
* **Dynamic Security:** The workflow dynamically fetches the GitHub Actions runner's IP address and injects it into the AWS Security Group for Just-In-Time (JIT) SSH access, maintaining a locked-down perimeter.
* **Unified Pipeline:** A single-job runner executes both Terraform and Ansible to preserve state and IP consistency throughout the deployment lifecycle.

### 2. Infrastructure as Code (Terraform)
* **AWS Foundation:** Automates the creation of a VPC, subnets, routing tables, and an EC2 instance (`ami-ubuntu`).
* **Remote State Management:** Utilizes an S3 bucket for backend state storage and a DynamoDB table for state locking to prevent concurrent deployment collisions.
* **Least-Privilege IAM:** Implements strict, customized IAM roles and instance profiles rather than relying on broad administrative permissions.

### 3. Configuration Management (Ansible)
* **Host Bootstrapping:** Automates package updates and the installation of Docker and Docker Compose V2 on the raw EC2 instance.
* **Code Synchronization:** Securely copies the application repository to the remote host.
* **Container Orchestration:** Executes the application build and deployment via Compose.

### 4. Application Layer (Docker Compose)
* **Backend:** A lightweight Python **FastAPI** service handling asynchronous HTTP requests.
* **Frontend/Proxy:** An **Nginx** container serving a static HTML dashboard and acting as a reverse proxy to route `/api/*` requests internally to the backend.
* **Network Isolation:** The backend API is completely hidden from the public internet, exposed only to the Nginx reverse proxy via an internal Docker bridge network.

---

## 📁 Repository Structure

```text
.
├── .github/workflows/
│   ├── automation.yml         # General automation triggers
│   ├── destroy.yml            # Safe teardown pipeline with manual confirmation
│   ├── full-deploy.yml        # Main infrastructure and application deployment pipeline
│   └── test-oidc.yml          # OIDC authentication test workflow
├── ansible/
│   └── playbook.yml           # Configuration management and app deployment steps
├── app/
│   ├── backend/               # FastAPI application, dependencies, and Dockerfile
│   ├── frontend/              # HTML dashboard, Nginx reverse proxy config, and Dockerfile
│   └── docker-compose.yml     # Multi-container orchestration
├── terraform/
│   ├── scripts/
│   │   └── the_bootstrap.sh   # Initialization script
│   ├── data.tf                # AWS data sources
│   ├── iam.tf                 # Least-privilege IAM Roles and OIDC policies
│   ├── instances.tf           # EC2 instance provisioning
│   ├── keys.tf                # SSH key pair management
│   ├── main.tf                # Core AWS provider and backend config
│   ├── outputs.tf             # Public IP and resource ID outputs
│   ├── s3.tf                  # S3 bucket configuration
│   ├── security_groups.tf     # Dynamic and static firewall rules
│   ├── terraform.tfvars.example # Template for variable inputs
│   ├── variables.tf           # Variable definitions
│   └── vpc.tf                 # Virtual Private Cloud and routing setup
├── .gitignore                 # Git ignore file
└── README.md                  # Project documentation
```
## How to Run

1. Navigate to the Actions tab in GitHub.
2. Select the Full Stack Deployment (GitOps) workflow.
3. Click Run workflow.
4. Once completed, the deployment summary will output the public URL of the live dashboard.

To tear down the environment:
1. Select the Terraform Destroy workflow.
2. Type destroy in the required confirmation input to prevent accidental deletions.
3. Click Run workflow to safely dismantle all AWS resources.

### ⚙️ Setup & Prerequisites

To run this pipeline, the following secrets must be configured in the GitHub Repository:

| Secret Name | Description |
|---|---|
AWS_ROLE_ARN| The ARN of the AWS IAM Role configured for GitHub OIDC federation.|
MY_IP| Your local workstation IP address formatted as a CIDR (e.g., 203.0.113.5/32) for manual SSH access. |
EC2_PUBLIC_KEY|The public SSH key to be injected into the EC2 authorized_keys file by Terraform.|
EC2_SSH_KEY| The private SSH key used by Ansible via GitHub Actions to connect and configure the instance.|