```bash
#!/bin/bash
set -e

echo "======================================"
echo "Building Docker Image"
echo "======================================"

if [ -z "$DOCKER_IMAGE" ]; then
    echo "ERROR: DOCKER_IMAGE is not set"
    exit 1
fi

if [ ! -d "build" ]; then
    echo "ERROR: build/ directory not found"
    exit 1
fi

docker build -t "$DOCKER_IMAGE" .

echo "Docker image built successfully: $DOCKER_IMAGE"
```