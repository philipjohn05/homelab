#!/bin/bash
set -e

if [ -z "$AZP_URL" ]; then
  echo "ERROR: AZP_URL environment variable is required"
  exit 1
fi

if [ -z "$AZP_TOKEN" ]; then
  echo "ERROR: AZP_TOKEN environment variable is required"
  exit 1
fi

AZP_POOL=${AZP_POOL:-Default}
AZP_AGENT_NAME=${AZP_AGENT_NAME:-$(hostname)}

echo "1. Configuring Azure Pipelines agent..."
echo "   URL: $AZP_URL"
echo "   Pool: $AZP_POOL"
echo "   Agent: $AZP_AGENT_NAME"

./config.sh --unattended \
  --url "$AZP_URL" \
  --auth PAT \
  --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" \
  --agent "$AZP_AGENT_NAME" \
  --replace \
  --acceptTeeEula

echo "2. Starting Azure Pipelines agent..."
exec ./run.sh
