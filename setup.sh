#!/bin/bash
echo "Fetching secrets from AWS..."

# Fetch as ubuntu1 (has AWS credentials)
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id todo/app/credentials/2 \
  --region ap-south-1 \
  --query SecretString \
  --output text)

export MONGO_USER=$(echo $SECRET | python3 -c "import json,sys; print(json.load(sys.stdin)['MONGO_USER'])")
export MONGO_PASSWORD=$(echo $SECRET | python3 -c "import json,sys; print(json.load(sys.stdin)['MONGO_PASSWORD'])")

echo "✅ Secrets loaded into memory"

# Pass variables explicitly to sudo
sudo -E docker compose up --build