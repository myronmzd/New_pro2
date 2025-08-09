#!/bin/bash
set -e

echo "[Setup] Installing Terraform..."
install -o root -g root -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor > /etc/apt/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y terraform

echo "[Setup] Installing Python packages..."
pip3 install --upgrade pip
pip3 install ansible python-hcl2 psycopg2-binary boto3

echo "[Setup] Setting correct permissions..."
chown -R vscode:vscode /workspaces/New_pro2

echo "[Setup] Done!"
terraform -version
docker --version