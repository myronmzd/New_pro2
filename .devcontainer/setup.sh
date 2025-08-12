#!/bin/bash
set -e

echo "[Setup] Updating packages..."
sudo apt-get update

echo "[Setup] Installing base tools..."
sudo apt-get install -y \
  gnupg \
  software-properties-common \
  curl \
  unzip \
  wget \
  jq \
  python3-pip \
  git \
  build-essential \


echo "[Setup] Installing Terraform..."
sudo install -o root -g root -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /etc/apt/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
terraform -version

echo "[Setup] Installing Python packages..."
pip3 install --upgrade pip
pip3 install ansible python-hcl2 boto3

echo "[Setup] Cleaning up..."
sudo apt-get clean

echo "[Setup] Completed successfully."
