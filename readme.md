# Pet Management System

A simple app to report and find missing pets.

## Setup
```bash
git clone <repo-url> && cd petmanagement && docker-compose up --build
```

## Tech Stack
- Angular frontend
- Node.js backend  
- MongoDB database
- Docker containers

## Auto Deployment
Push to main branch → automatically deploys to EC2 with public ngrok URL

### Required GitHub Secrets
Add these in Settings → Environments → petman_secrets:
- `DOCKERHUB_USERNAME` - Your Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token
- `EC2_HOST` - EC2 public IP address
- `EC2_USERNAME` - EC2 username (ubuntu/ec2-user)
- `EC2_SSH_KEY` - Private SSH key content (.pem file)