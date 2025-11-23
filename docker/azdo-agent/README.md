# Azure DevOps Agent Docker Image

Custom Azure DevOps agent built for Kubernetes deployment.

## Features
- Ubuntu 22.04 base
- Azure Pipelines Agent v3.236.1
- kubectl v1.28.0 pre-installed
- Docker CLI pre-installed
- Modern AZP_* environment variables

## Building

### Prerequisites
Download the Azure Pipelines agent:
```bash
# Download from GitHub releases
curl -LO https://github.com/microsoft/azure-pipelines-agent/releases/download/v3.236.1/vsts-agent-linux-x64-3.236.1.tar.gz

# Verify size (~180MB)
ls -lh vsts-agent-linux-x64-3.236.1.tar.gz
```

### Build with Kaniko in Kubernetes

Due to network restrictions, the agent tarball must be pre-downloaded and included in the build context.

See repository documentation for detailed build instructions using Kaniko.

## Usage

Image is deployed via FluxCD GitOps in `apps/base/azure-devops/deployment.yaml`

## Image Details

- **Registry:** Docker Hub
- **Image:** `pjsleepless/azdo-agent:v1`
- **Size:** ~400MB (vs 3.8GB Microsoft image)
- **Base:** Ubuntu 22.04
- **Agent:** Azure Pipelines Agent v3.236.1

## Environment Variables

- `AZP_URL` - Azure DevOps organization URL (required)
- `AZP_TOKEN` - Personal Access Token (required)
- `AZP_POOL` - Agent pool name (default: "Default")
- `AZP_AGENT_NAME` - Agent name (default: hostname)
- `DOCKER_HOST` - Docker daemon address (default: tcp://localhost:2375)

## Notes

- Agent tarball is NOT included in Git (too large, 180MB)
- Must be downloaded separately before building
- Download URL is stable and maintained by Microsoft
