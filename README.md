# Full-Stack GitOps Deployment on AWS

A single GitHub Actions workflow that provisions AWS infrastructure with Terraform, waits for the instance to come up, then hands off to Ansible to build and run a containerized app on it — triggered by one button click, zero manual steps in between.

**The point of this project is the automation, not the app.** The app is a deliberately thin two-container proof-of-concept (no database) used to prove the pipeline actually deploys something real end to end. See [Scope](#scope) below.

---

## Architecture

```
GitHub Actions (workflow_dispatch)
        │
        ├─ OIDC auth → short-lived AWS credentials (no stored keys)
        ├─ Fetch runner's public IP → passed to Terraform as var.ci_runner_ip
        │
        ▼
Terraform apply
        ├─ VPC, public subnet, IGW, route table
        ├─ Security Group — SSH allowed from var.my_ip + var.ci_runner_ip only, HTTP 80 open
        ├─ EC2 (t3.micro, dynamic Ubuntu 22.04 AMI lookup)
        ├─ IAM role — scoped to s3:GetObject on the bootstrap bucket only
        └─ S3 (encrypted, remote state) + DynamoDB (state locking)
        │
        ▼
Wait for SSH to come up (retry loop, ~5 min max)
        │
        ▼
Ansible playbook (over SSH, key from GitHub Secret)
        ├─ apt install docker.io, docker-compose-v2
        ├─ copy app/ → /opt/gitops-app on the instance
        └─ docker compose up -d --build   (images built ON the instance)
        │
        ▼
App live at http://<EC2_PUBLIC_IP>
```

---

## Scope

This was built to prove a specific thing: **can one click take you from nothing to a running app on AWS, with no manual AWS console work, no long-lived credentials, and infrastructure that's fully reproducible?** Yes — that's the deliverable.

What's intentionally *not* here:

- **No database.** The app is two containers (FastAPI + Nginx), not three. `main.py`'s `/api/data` response even hardcodes `"db_status": "connected"` — there's no actual DB behind it. Adding Postgres would mean solving data persistence, volumes, and backup/restore, which is a different (and bigger) problem than the one this project is about.
- **No automated health check.** The pipeline's final step prints a success message unconditionally — it doesn't actually curl `/api/health` to confirm the app responded. The endpoint exists; the pipeline just doesn't check it yet.
- **SSH access list doesn't self-clean.** Every pipeline run adds the current CI runner's IP to the security group alongside your own; nothing removes IPs from previous runs. Fine for a personal project, would need addressing for anything long-lived.

---

## Repository Structure

```text
.
├── .github/workflows/
│   ├── full-deploy.yml        # Main pipeline: Terraform apply → wait for SSH → Ansible deploy
│   ├── destroy.yml            # Teardown, gated by typed "destroy" confirmation
│   ├── automation.yml         # Terraform plan/apply only (no Ansible/app step)
│   └── test-oidc.yml          # Diagnostic — verifies OIDC auth works via `aws sts get-caller-identity`
├── ansible/
│   └── playbook.yml           # Installs Docker, copies app/, runs docker compose up --build
├── app/
│   ├── backend/                # FastAPI — /api/health, /api/data
│   ├── frontend/                # Static HTML + Nginx reverse proxy (routes /api/* to backend)
│   └── docker-compose.yml     # backend (internal only) + frontend (port 80, public)
├── terraform/
│   ├── main.tf                 # Provider + S3/DynamoDB backend config
│   ├── vpc.tf                  # VPC, subnet, IGW, routing
│   ├── security_groups.tf     # SSH restricted to var.my_ip + var.ci_runner_ip, HTTP open
│   ├── instances.tf            # EC2 provisioning + user_data bootstrap
│   ├── iam.tf                  # Least-privilege IAM role/instance profile
│   ├── keys.tf                 # EC2 key pair (public key from GitHub Secret)
│   ├── s3.tf                   # Bootstrap script bucket
│   ├── data.tf                 # Dynamic AMI lookup
│   ├── outputs.tf              # Public IP output, consumed by the workflow
│   ├── variables.tf
│   ├── terraform.tfvars.example
│   └── scripts/the_bootstrap.sh  # user_data — installs Docker only, app deploy left to Ansible
├── .gitignore
└── README.md
```

---

## How to Run

1. Go to **Actions** → **Full Stack Deployment (GitOps)** → **Run workflow**.
2. Wait for it to finish — it provisions the instance, waits for SSH, then deploys the app.
3. Visit `http://<EC2_PUBLIC_IP>` (shown in the workflow's final step log).

To tear down:

1. Go to **Actions** → **Terraform Destroy** → **Run workflow**.
2. Type `destroy` in the confirmation input.
3. Run — this removes all AWS resources.

`Test AWS OIDC Connection` is a standalone diagnostic, not part of the deploy flow — run it on its own if you need to verify GitHub↔AWS auth is working before debugging anything else.

---

## Required GitHub Secrets

| Secret | Used by | Purpose |
|---|---|---|
| `AWS_ROLE_ARN` | All workflows | ARN of the IAM role GitHub assumes via OIDC |
| `MY_IP` | `full-deploy.yml`, `automation.yml`, `destroy.yml` | Your IP (CIDR), allowed for manual SSH |
| `EC2_PUBLIC_KEY` | Terraform | Public key injected into the instance's `authorized_keys` |
| `EC2_SSH_KEY` | `full-deploy.yml` | Private key Ansible uses to SSH in and deploy |

The workflow also computes `TF_VAR_ci_runner_ip` at runtime (the GitHub runner's own IP) so Ansible can reach the instance over SSH during the same run — this one isn't a secret, it's fetched fresh each time via `curl ifconfig.me`.

---

## Stack

| Layer | Tech |
|---|---|
| CI/CD | GitHub Actions, OIDC (keyless AWS auth) |
| Infra | Terraform (VPC, EC2, SG, IAM, S3, DynamoDB) |
| Config management | Ansible |
| App | FastAPI (backend) + Nginx reverse proxy + static HTML (frontend) |
| Container runtime | Docker / Docker Compose V2, built on-instance |

---

## Security Decisions

A few of the infrastructure choices here were made deliberately rather than defaulted into. Worth stating why.

**OIDC instead of static AWS access keys.** GitHub Actions authenticates to AWS via OpenID Connect federation, not a stored `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` pair. The workflow requests a short-lived, per-run token from GitHub's OIDC provider, which AWS exchanges for temporary credentials scoped to that run. There's nothing long-lived to leak, rotate, or accidentally commit — if a secret gets exposed, it's a token that's already expired by the time anyone could use it.

**IAM scoped to one action on one resource.** The EC2 instance role only has `s3:GetObject` on its own bootstrap bucket — not read/write, not other buckets, not any other service. The blast radius of a compromised instance is "can read one script from one bucket," not "can touch the AWS account." Same principle applied to the OIDC role itself: it's scoped to what Terraform actually needs to provision, not broad admin access.

**SSH restricted to known IPs, not open to the internet.** The security group only allows port 22 from `var.my_ip` (your workstation) and `var.ci_runner_ip` (fetched fresh each pipeline run). Port 80 is open, because that's the actual application surface meant to be public — but the management plane (SSH) isn't exposed to `0.0.0.0/0` the way a lot of quick EC2 setups default to.

**No credentials or IPs hardcoded in the repo.** `MY_IP`, `EC2_PUBLIC_KEY`, and `EC2_SSH_KEY` all live in GitHub Secrets, injected as `TF_VAR_*` environment variables at runtime — never written to disk in the repo, never visible in `git log`. The only thing computed inline is the CI runner's IP, which isn't sensitive.

**Remote state, encrypted and locked.** Terraform state — which can contain sensitive values — lives in an encrypted S3 bucket rather than a local `.tfstate` file that could end up committed by accident. DynamoDB handles state locking, so two `apply` runs can't race and corrupt each other.

None of this makes the project "a security project" — it's the same reasoning any DevOps setup should apply by default. But it's deliberate, not accidental, and worth being able to explain in those terms.

---

## Possible Next Steps

- Add an actual `curl` health check against `/api/health` before the pipeline reports success.
- Clean up stale runner IPs from the security group on each run (or on `destroy`).
- Swap the hardcoded `db_status: "connected"` for a real database if the project scope ever grows.