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
- Monitoring: AWS CloudWatch (Logs, Metric Filters, Alarms)

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Basic index route |
| GET | `/health` | Health check — verifies Redis connectivity |
| GET | `/items` | Returns all stored items |
| POST | `/items` | Adds an item (`{"item": "..."}`) to the list |

### Usage

```bash
# Add an item
curl -X POST http://localhost/items \
    -H "Content-Type: application/json" \
    -d '{"item": "cat"}'
# -> {"item": "cat", "message": "Item added"}

# Get all items
curl http://localhost/items
# -> {"items": ["cat"]}

# DB Health check
curl http://localhost/health
# -> {"status": "healthy", "redis": "connected"}
```

## Monitoring

| Log Group | Captures | Retention |
|---|---|---|
| `/cloudpipe/app` | Container stdout/stderr for the web and redis services (via Docker's awslogs driver) | 3 days |

| Alarm | Watches | Triggers when |
|---|---|---|
| `cloudpipe-high-cpu` | `CPUUtilization (AWS/EC2)` | Avg CPU > 80% for 1 minute |
| `cloudpipe-status-check-failed` | `StatusCheckFailed` (AWS/EC2) | Any failed status check |
| `cloudpipe-app-errors` | Custom metric from a log metric filter matching `"ERROR"` om `cloudpipe/app` | Any ERROR line logged |

## Design Decisions & Tradeoffs

- **Ephemeral infrastructure over persistent environment**: The pipeline provisions AWS infrastructure fresh on every deploy (to main) and destroys it after the health check passes, rather than deploying to a long-lived environment. This keeps costs near-zero and forces the whole provisioning process to be fully automated and repeatable - the tradeofff is slower iteration (each run pays the cost of spinning up a VPC/EC2 instance from scratch).

- **Remote Terraform with state locking**: State is stored in S3 with locking enabled rather than locally, so the pipeline can run safely without state conflicts. Even though this is a single-contributer project, setting it up this way would replicate how a team project would need it to be.

- **Public ECR over private ECR**: Chose ECR Public for simplicity, no additional auth complexity for pulling images, and because of the more generous tier of ECR Public. However in a production setting, this should be changed to ECR Private.

- **Container-level logs over full host observability**: CloudWatch Logs are wired up via Docker's `awslogs` driver, capturing the application and Redis container output (stdout/stderr). I chose not to log EC2 host-level OS logs because full host observability would rqeuire installing and configuring a CloudWatch Agent separately.

- **Split compose files for environment-specific logging**: `docker-compose.prod.yaml` overlays CloudWatch logging config onto the base `docker-compose.yaml`, since the `awslogs` driver requires AWS credential available only on EC2 (via its IAM role), keeping it out of the base file lets the app run locally without CloudWatch dependencies.

## Getting Started (local)

```bash
# clone the repo
git clone https://github.com/Karen-W-2002/CloudPipe.git
cd CloudPipe

# run app + redis locally
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
