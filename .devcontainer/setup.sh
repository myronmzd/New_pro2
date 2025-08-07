#!/bin/bash
set -e

echo "[Setup] Updating packages..."
sudo apt-get update -y

echo "[Setup] Installing basic tools..."
sudo apt-get install -y curl wget unzip git jq python3-pip

echo "[Setup] Installing latest Go..."
GO_VERSION=1.22.0
wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
rm go${GO_VERSION}.linux-amd64.tar.gz

echo "[Setup] Installing Terraform..."
sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update -y
sudo apt-get install -y terraform

echo "[Setup] Installing Python tools..."
pip3 install --upgrade pip
pip3 install awscli ansible

echo "[Setup] Cleaning up..."
sudo apt-get clean

echo "[Setup] Setup completed successfully!"
