#!/bin/bash
set -e


echo "[Setup] Installing base tools..."
sudo apt install -y \
  gnupg \
  software-properties-common \
  curl \
  unzip \
  wget \
  jq \
  python3-pip \
  git \
  build-essential


echo "[Setup] Updating packages..."
apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo "[Setup] Adding Docker's GPG key..."
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "[Setup] Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

echo "[Setup] Installing Docker..."
apt-get update && apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "[Setup] Starting Docker daemon..."
dockerd &

echo "[Setup] Docker installation complete."
docker --version

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

echo "[Setup] Updating packages..."
sudo apt-get update && sudo apt-get upgrade -y
