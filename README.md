# CloudPipe
 
An automated CI/CD pipeline that builds, provisions, tests, and tears down a containerized Flask/Redis service on AWS. Infrastructure fully defined as code with Terraform, orchestrated end-to-end through GitHub Actions.

![test workflow](https://github.com/Karen-W-2002/CloudPipe/actions/workflows/test.yml/badge.svg)
![deploy application workflow](https://github.com/Karen-W-2002/CloudPipe/actions/workflows/deploy.yml/badge.svg)

## Overview

CloudPipe is a small Flask + Redis service wrapped in a complete, automated deployment pipeline. Every push triggers a pipeline that:

1. Lints and tests the application code
2. Builds a Docker image and pushes it to Amazon ECR Public
3. Provisions AWS infrastructure from scratch with Terraform (VPC, subnet, security groups, EC2 instance)
4. Deplloys the containerized app + Redis to the newly provisioned EC2 instance
5. Runs live health checks against the deployed service
6. Tears down the infrastructure automatically via `terraform destroy`

The goal of CloudPipe was to build a realistic, self-contained example of IAC and CI/CD working together, including ephemeral environments and automated teardown to avoid ongoing cloud costs.

## Architecture

```
GitHub push
     │
     ▼
[test.yml] ── flake8 + pytest
     │ (on success)
     ▼
[deploy.yml]
     │
     ├─► Build Docker image ──► Push to Amazon ECR (Public)
     │
     ├─► Terraform apply ──► Provision VPC / Subnet / Security Groups / EC2 + IAM role
     │        (state stored remotely in S3, with state locking)
     │
     ├─► SSH into EC2 ──► docker compose up (Flask app + Redis)
     │
     ├─► Health checks ──► GET / and GET /health
     │
     └─► Terraform destroy ──► Infrastructure torn down
```

## Tech Stack

- **Application**: Python, Flask, Redis
- **Testing**: pytest, fakeredis, flake8
- **Containerization**: Docker, Docker Compose
- **Infrastructure as Code**: Terraform (VPC, subnets, security groups, EC2, IAM), remote state in S3 with state locking
- **CI/CD**: Github Actiosn
- **Cloud**: AWS (EC2, ECR Public, S3, VPC, IAM)

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Basic index route |
| GET | `/health` | Health check — verifies Redis connectivity |
| GET | `/items` | Returns all stored items |
| POST | `/items` | Adds an item (`{"item": "..."}`) to the list |

## Design Decisions & Tradeoffs

- **Ephemeral infrastructure over persistent environment**: The pipeline provisions AWS infrastructure fresh on every deploy (to main) and destroys it after the health check passes, rather than deploying to a long-lived environment. This keeps costs near-zero and forces the whole provisioning process to be fully automated and repeatable - the tradeofff is slower iteration (each run pays the cost of spinning up a VPC/EC2 instance from scratch).

- **Remote Terraform with state locking**: State is stored in S3 with locking enabled rather than locally, so the pipeline can run safely without state conflicts. Even though this is a single-contributer project, setting it up this way would replicate how a team project would need it to be.

- **Public ECR over private ECR**: Chose ECR Public for simplicity, no additional auth complexity for pulling images, and because of the more generous tier of ECR Public. However in a production setting, this should be changed to ECR Private.

## Getting Started (local)

**clone the repo**
```
git clone https://github.com/Karen-W-2002/CloudPipe.git
cd CloudPipe
```

**run app + redis locally**
```
export APP_IMAGE=cloudpipe-web:local
export REDIS_HOST=redis
docker compose up --build
```

The app will be available at `http://localhost:80`.

## Running Tests

```bash
cd app
pip install -r ../requirements.txt
pytest
```

## Roadmap

- [x] Add CloudWatch monitoring/logging for the deployed EC2 instance
- [ ] Add architecture diagram image
- [ ] Restrict SSH ingress (port 22) to a specific IP instead of `0.0.0.0/0` in security_groups.tf
- [ ] Expand test coverage beyond core API routes
- [ ] more...
