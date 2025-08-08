#!/bin/bash
set -e

echo "[Setup] Updating packages..."
sudo apt-get update && sudo apt-get upgrade -y

echo "[Setup] Installing base tools..."
sudo apt update
sudo apt install -y \
  gnupg \
  software-properties-common \
  curl \
  unzip \
  wget \
  jq \
  python3-pip \


echo "[Setup] Installing Terraform..."
sudo install -o root -g root -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /etc/apt/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
terraform -version

echo "[Setup] Installing Python packages..."
pip3 install --upgrade pip
pip3 install ansible python-hcl2 psycopg2-binary boto3

echo "[Setup] Cleaning up..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/* /var/tmp/*

echo "[Setup] Setting correct permissions..."
sudo chown -R vscode:vscode /workspaces/New_pro2