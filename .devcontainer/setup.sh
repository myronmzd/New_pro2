#!/bin/bash
set -e  # Stop if any command fails

echo "[Setup] Updating packages..."
apt-get update && apt-get upgrade -y

echo "[Setup] Installing dependencies..."
apt-get install -y gnupg software-properties-common curl unzip postgresql-client

echo "[Setup] Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y terraform
terraform -version

echo "[Setup] Installing Python tools..."
python3 -m pip install --upgrade pip
pip3 install ansible python-hcl2 psycopg2-binary


echo "[Setup] Cleaning up..."
apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
