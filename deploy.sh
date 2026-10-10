#!/bin/bash

set -e

echo "======================================"
echo "Production Deployment"
echo "======================================"

DOCKER_IMAGE="IMAGE_PLACEHOLDER"

echo "Deploying:"
echo "$DOCKER_IMAGE"

echo ""
echo "Pulling Docker image..."

docker pull "$DOCKER_IMAGE"

echo ""
echo "Stopping old application..."

docker compose down

echo ""
echo "Starting new application..."

docker compose up -d

echo ""
echo "Checking containers..."

docker compose ps

echo ""
echo "Waiting for application..."

sleep 5

echo ""
echo "Checking application health..."

if curl -fs http://localhost/; then

    echo ""
    echo "Application is UP."

else
    echo ""
    echo "Application health check FAILED."

    docker compose logs

    exit 1

fi

echo ""
echo "======================================"
echo "Deployment Completed"
echo "======================================"