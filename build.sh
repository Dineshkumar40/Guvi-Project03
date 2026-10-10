#!/bin/bash
set -e

echo "======================================"
echo "Building React Application"
echo "======================================"

# Docker image placeholder
DOCKER_IMAGE="IMAGE_PLACEHOLDER"
echo "Docker Image: $DOCKER_IMAGE"

echo ""
echo "Installing dependencies..."
npm ci

echo ""
echo "Building React application..."

npm run build

echo ""
echo "Building Docker image..."

docker build -t "$DOCKER_IMAGE" .

echo ""
echo "Build completed successfully."