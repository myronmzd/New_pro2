#!/bin/bash
set -e

echo "[Setup] Updating packages..."
apt-get update && apt-get upgrade -y

echo "[Setup] Installing base tools..."
apt-get install -y \
    gnupg \
    software-properties-common \
    ca-certificates \
    curl \
    unzip \
    wget \
    jq \
    python3-pip \
    git \
    build-essential \
    lsb-release

echo "[Setup] Adding Docker's GPG key & repo..."
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
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
dockerd &

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

echo "[Setup] Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/*

echo "[Setup] Setting correct permissions..."
chown -R vscode:vscode /workspaces/New_pro2

echo "[Setup] Done!"
docker --version
terraform -version
