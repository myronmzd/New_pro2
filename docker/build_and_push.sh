#!/usr/bin/env bash
set -euo pipefail

AWS_REGION=${1:-$(aws configure get region)}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_NAME="yolov8-video-processor"
TAG=${2:-latest}
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${TAG}"

# create repo if missing
aws ecr describe-repositories --repository-names "${REPO_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "${REPO_NAME}" --region "${AWS_REGION}"

# login
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# build with correct context
docker build -t "${REPO_NAME}:${TAG}" -f Dockerfile app/
docker tag "${REPO_NAME}:${TAG}" "${IMAGE_URI}"
docker push "${IMAGE_URI}"

echo "Pushed image: ${IMAGE_URI}"
echo "Use this value for CloudFormation parameter ContainerImage."
