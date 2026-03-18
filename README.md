# gitops-aws-pipeline

> Full-stack GitOps deployment pipeline — GitHub Actions → Terraform → Ansible → Docker on AWS.  
> Zero manual clicks from commit to running application.

---

## What This Is

A fully automated CI/CD pipeline that provisions cloud infrastructure, configures servers, and deploys a three-tier containerized web application on AWS — triggered by a single `git push`. No manual console interaction after initial setup.

This project demonstrates the complete DevOps delivery lifecycle:

- **Infrastructure as Code** — Terraform provisions the entire AWS environment reproducibly
- **Configuration as Code** — Ansible hardens the OS and prepares the server automatically
- **Container Delivery** — Docker packages and runs the application stack
- **Pipeline Orchestration** — GitHub Actions ties everything together with keyless OIDC authentication

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                        │
│                                                                 │
│   git push → GitHub Actions Workflow (.github/workflows/)       │
│                          │                                      │
│          ┌───────────────┼───────────────┐                      │
│          ▼               ▼               ▼                      │
│     OIDC Auth       terraform        ansible                    │
│     (No keys)        apply          playbook                    │
└──────────┼───────────────┼───────────────┼──────────────────────┘
           │               │               │
           ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AWS (us-east-1)                          │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                 VPC (10.0.0.0/16)                       │   │
│   │                                                         │   │
│   │   ┌─────────────────────────────────────────────────┐   │   │
│   │   │         Public Subnet (10.0.1.0/24)             │   │   │
│   │   │                                                 │   │   │
│   │   │   ┌─────────────────────────────────────────┐   │   │   │
│   │   │   │         EC2 (t2.micro)                  │   │   │   │
│   │   │   │                                         │   │   │   │
│   │   │   │   ┌──────────┐  ┌──────────┐            │   │   │   │
│   │   │   │   │ Frontend │  │ Backend  │            │   │   │   │
│   │   │   │   │  React   │  │ FastAPI  │            │   │   │   │
│   │   │   │   │  :80     │  │  :8000   │            │   │   │   │
│   │   │   │   └──────────┘  └──────────┘            │   │   │   │
│   │   │   │         ┌──────────────┐                │   │   │   │
│   │   │   │         │   Database   │                │   │   │   │
│   │   │   │         │  PostgreSQL  │                │   │   │   │
│   │   │   │         │   :5432      │                │   │   │   │
│   │   │   │         └──────────────┘                │   │   │   │
│   │   │   │    Docker Compose (managed by Ansible)  │   │   │   │
│   │   │   └─────────────────────────────────────────┘   │   │   │
│   │   └─────────────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│   S3 Bucket — Terraform Remote State                            │
│   DynamoDB Table — State Locking                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Role |
|---|---|---|
| **Pipeline** | GitHub Actions | Triggers workflow, manages OIDC auth, orchestrates all stages |
| **Infrastructure** | Terraform | Provisions VPC, subnets, security groups, EC2, S3, DynamoDB |
| **Configuration** | Ansible | Hardens OS, installs Docker, deploys application |
| **Frontend** | React + Nginx | Serves the UI |
| **Backend** | Python (FastAPI) | Handles API logic and database queries |
| **Database** | PostgreSQL | Persistent data storage via Docker volume |
| **Cloud** | AWS | Hosting environment |
| **Auth** | OIDC (Keyless) | Zero hardcoded credentials — federated trust between GitHub and AWS IAM |

---

## Repository Structure

```
gitops-aws-pipeline/
│
├── .github/
│   └── workflows/
│       └── main.yml            # GitHub Actions pipeline definition
│
├── terraform/
│   ├── main.tf                 # Provider config and backend (S3 + DynamoDB)
│   ├── vpc.tf                  # VPC, subnets, internet gateway, route tables
│   ├── security_groups.tf      # Ingress/egress rules
│   ├── instances.tf            # EC2 instance definition
│   ├── iam.tf                  # OIDC identity provider and IAM role
│   ├── outputs.tf              # EC2 public IP output for Ansible
│   └── variables.tf            # Input variables
│
├── ansible/
│   ├── playbook.yml            # Main playbook — hardens server, installs Docker
│   └── inventory/
│       └── hosts.ini           # Dynamically populated by pipeline (gitignored)
│
├── app/
│   ├── frontend/               # React application
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── nginx.conf
│   ├── backend/                # FastAPI application
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   └── docker-compose.yml      # Orchestrates all three containers
│
├── .gitignore
└── README.md
```

---

## Pipeline Flow

A `git push` to `main` triggers the following sequence — fully automated, zero manual steps:

```
1. GitHub Actions starts
        │
        ▼
2. OIDC authentication → AWS issues short-lived credentials
        │
        ▼
3. terraform fmt & validate (linting)
        │
        ▼
4. terraform apply → VPC, Security Groups, EC2 provisioned
        │
        ▼
5. EC2 Public IP captured from Terraform output
        │
        ▼
6. Ansible inventory dynamically populated with new IP
        │
        ▼
7. Ansible playbook executes → Docker installed, server hardened
        │
        ▼
8. docker-compose up -d → All three containers running
        │
        ▼
9. Health check → Pipeline verifies application returns HTTP 200
        │
        ▼
10. Done. Application live at EC2 Public IP.
```

---

## Security Highlights

**Keyless Authentication (OIDC)** — GitHub Actions authenticates to AWS via OpenID Connect federated trust. No AWS access keys or secret keys are stored anywhere. GitHub receives short-lived, scoped credentials per pipeline run.

**Least Privilege IAM** — The IAM role assumed by the pipeline is scoped to only the permissions required for provisioning. No wildcard policies.

**Remote State with Locking** — Terraform state is stored in S3 with DynamoDB locking to prevent concurrent state corruption.

**No Hardcoded Values** — All sensitive configuration (database passwords, SSH keys) lives in GitHub Secrets and is injected at pipeline runtime. Nothing sensitive is committed to the repository.

---

## Definition of Success

This project is complete when:

- A `git push` to `main` triggers the full pipeline with zero manual intervention
- The pipeline provisions infrastructure, configures the server, and deploys the application end to end
- The application survives a container restart with data intact (PostgreSQL volume persistence)
- Re-running the pipeline against an unchanged codebase results in no changes (idempotency)
- Zero AWS credentials exist anywhere in the repository or pipeline logs

---

## Prerequisites (For Local Development)

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.14
- [Docker](https://docs.docker.com/get-docker/) + Docker Compose
- AWS CLI configured with credentials
- An SSH key pair for EC2 access

---

## Status

🚧 **In active development** — See commit history for progress.

| Phase | Status |
|---|---|
| Local proof of concept (Docker Compose) | 🟡 In progress |
| Phase I — Terraform infrastructure | ⬜ Not started |
| Phase II — Ansible configuration | ⬜ Not started |
| Phase III — Docker application deployment | ⬜ Not started |
| Phase IV — GitHub Actions pipeline | ⬜ Not started |
| Health check & validation | ⬜ Not started |
| Documentation & architecture diagram | 🟡 In progress |