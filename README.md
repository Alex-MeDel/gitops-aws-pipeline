# gitops-aws-pipeline

> Full-stack GitOps deployment pipeline — GitHub Actions → Terraform → Ansible → Docker on AWS.
> Zero manual clicks from commit to running application.

---

## Status (as of today)

| Layer | Status |
|---|---|
| Terraform infrastructure (VPC, EC2, SG, IAM, S3) | ✅ Live |
| Remote state (S3 + DynamoDB locking, encrypted) | ✅ Live |
| GitHub Actions CI (OIDC, plan/apply/destroy) | ✅ Working, manual trigger only |
| EC2 bootstrap (user_data → Docker installed) | ✅ Working, minimal by design |
| Local app (React + FastAPI + PostgreSQL via docker-compose) | ⬜ Not started — next up |
| Ansible provisioning/config | ⬜ Not started |
| Ansible app deployment (docker-compose up on EC2) | ⬜ Not started |
| Auto-trigger on push to `main` | ⬜ Disabled on purpose (commented out) until app + Ansible are ready |

---

## Architecture (target state — pieces marked ✅ are live now)

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                        │
│                                                                 │
│   git push (manual dispatch for now) → GitHub Actions           │
│                          │                                      │
│          ┌───────────────┼───────────────┐                      │
│          ▼               ▼               ▼                      │
│     OIDC Auth ✅    terraform ✅      ansible ⬜                 │
│     (No keys)        apply           playbook                   │
└──────────┼───────────────┼───────────────┼──────────────────────┘
           │               │               │
           ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AWS (us-east-1)                          │
│                                                                 │
│   VPC (10.0.0.0/16) ✅                                          │
│     └─ Public Subnet (10.0.1.0/24) ✅                           │
│          └─ EC2 t3.micro ✅ (Ubuntu 22.04, dynamic AMI lookup)   │
│               ├─ user_data bootstrap ✅ → Docker installed only │
│               │    (app deploy intentionally left to Ansible)   │
│               └─ Frontend / Backend / Postgres containers ⬜    │
│                    (docker-compose, not built yet)               │
│                                                                 │
│   S3 — Terraform remote state (encrypted) ✅                    │
│   DynamoDB — State locking ✅                                   │
│   S3 — Bootstrap script storage ✅                               │
│   IAM Role (EC2) — scoped to s3:GetObject on bootstrap bucket ✅ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Status |
|---|---|---|
| **Pipeline** | GitHub Actions (OIDC, manual dispatch) | ✅ Working |
| **Infrastructure** | Terraform | ✅ Live |
| **Bootstrap** | EC2 user_data → Docker/Docker Compose/AWS CLI | ✅ Working (minimal) |
| **Configuration** | Ansible | ⬜ Not started |
| **Frontend** | React + Nginx | ⬜ Not started |
| **Backend** | Python (FastAPI) | ⬜ Not started |
| **Database** | PostgreSQL | ⬜ Not started |
| **Cloud** | AWS (us-east-1) | ✅ Live |
| **Auth** | OIDC (keyless) — GitHub ↔ AWS IAM federated trust | ✅ Live |

---

## Repository Structure (current)

```
gitops-aws-pipeline/
│
├── .github/
│   └── workflows/
│       ├── automation.yml      # Plan + apply, OIDC auth, manual dispatch
│       └── destroy.yml         # Teardown, gated by typed "destroy" confirmation
│
├── terraform/
│   ├── main.tf                 # Provider config
│   ├── variables.tf            # aws_region, my_ip, public_key, etc.
│   ├── data.tf                 # Dynamic Ubuntu 22.04 AMI lookup
│   ├── vpc.tf                  # VPC, subnet, IGW, route table
│   ├── security_groups.tf      # SSH (IP-restricted via var), HTTP 80 open
│   ├── keys.tf                 # EC2 key pair (public key from GitHub Secret)
│   ├── instances.tf            # EC2 t3.micro + user_data bootstrap
│   ├── iam.tf                  # EC2 IAM role, scoped to bootstrap bucket read
│   ├── s3.tf                   # Bootstrap script bucket (random suffix)
│   ├── outputs.tf              # Public IP, AMI ID
│   └── scripts/
│       └── the_bootstrap.sh    # Installs Docker/Compose/AWS CLI only
│
├── ansible/                    # ⬜ not started
├── app/                        # ⬜ not started
│
└── README.md
```

*(Terraform state backend — S3 + DynamoDB — is configured but not shown above; encryption and locking are enabled.)*

---

## Pipeline Flow (current, manual)

```
1. Trigger workflow manually (workflow_dispatch)
        │
        ▼
2. OIDC authentication → AWS issues short-lived credentials
        │
        ▼
3. terraform init → remote state (S3 + DynamoDB lock)
        │
        ▼
4. terraform plan → saved as artifact (-out=tfplan)
        │
        ▼
5. terraform apply → applies the exact saved plan (not a re-plan)
        │
        ▼
6. EC2 boots → user_data installs Docker/Compose/AWS CLI
        │
        ▼
7. (STOPS HERE for now — no app, no Ansible yet)
```

`destroy.yml` runs the same OIDC/init pattern but requires typing `"destroy"` as a manual confirmation input before it will tear anything down.

---

## Security Notes (current)

- **Keyless auth (OIDC)** — no AWS access keys anywhere, GitHub gets short-lived scoped credentials per run.
- **Least-privilege IAM** — EC2 instance role can only `s3:GetObject` on its own bootstrap bucket. Nothing else.
- **SSH locked to one IP** — value comes from `TF_VAR_my_ip`, stored as a GitHub Secret (`MY_IP`), not hardcoded in the repo.
- **SSH key not hardcoded** — public key comes from `TF_VAR_public_key` / `EC2_PUBLIC_KEY` GitHub Secret, not read from a local file path anymore.
- **State encrypted + locked** — S3 backend with encryption enabled, DynamoDB table prevents concurrent apply corruption.
- **Plan/apply consistency** — apply step uses the saved plan file, so what gets applied is exactly what was planned, not a fresh re-plan.
- **`db_password` reserved** — `TF_VAR_db_password` is planned as a GitHub Secret for when the Postgres container exists; not wired up yet since there's no app/db to configure.

---

## Next Steps

1. **Build the app locally** — React + FastAPI + PostgreSQL via `docker-compose`, confirmed working on laptop (API ↔ DB, UI ↔ API) before anything touches AWS.
2. **Write the Ansible playbook** — install Docker/Compose (redundant-safe with user_data), copy `docker-compose.yml`, run `docker-compose up -d`.
3. **Wire Ansible into the pipeline** — dynamic inventory from Terraform's EC2 IP output.
4. **Add health check step** — pipeline verifies app returns HTTP 200 post-deploy.
5. **Only then** consider re-enabling the push trigger on `main`.

---

## Prerequisites (Local Dev)

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.14 (not yet used)
- [Docker](https://docs.docker.com/get-docker/) + Docker Compose
- AWS CLI configured with credentials (local runs only — pipeline uses OIDC)
- An SSH key pair for EC2 access (public key goes in `TF_VAR_public_key` locally, or GitHub Secret `EC2_PUBLIC_KEY` in CI)
