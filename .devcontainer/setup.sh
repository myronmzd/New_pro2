#!/bin/bash
set -e

echo "[Setup] Updating packages..."
apt-get update && apt-get upgrade -y

echo "[Setup] Installing basic tools..."
apt-get install -y gnupg software-properties-common curl unzip postgresql-client python3-pip jq

echo "[Setup] Installing latest Go..."
LATEST_GO_VERSION=$(curl -s https://go.dev/dl/?mode=json | jq -r '.[0].version')
GO_TARBALL=${LATEST_GO_VERSION}.linux-amd64.tar.gz
curl -OL "https://go.dev/dl/${GO_TARBALL}"
rm -rf /usr/local/go
tar -C /usr/local -xzf "${GO_TARBALL}"
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin
go version
rm "${GO_TARBALL}"

echo "[Setup] Installing Terraform..."
install -o root -g root -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /etc/apt/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
apt update && apt install -y terraform
terraform -version

echo "[Setup] Installing Python tools..."
pip3 install --upgrade pip
pip3 install ansible python-hcl2 psycopg2-binary

echo "[Setup] Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/*
echo "[Setup] Setup completed successfully!"
echo "[Setup] Please restart your terminal or run 'source ~/.bashrc' to apply changes."