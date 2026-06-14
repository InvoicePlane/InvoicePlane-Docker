#!/bin/bash
set -euo pipefail

# Enter the workspace container with bash shell as ivpldock user

# Check if .env.docker exists
if [ ! -f .env.docker ]; then
    echo "Error: .env.docker file not found!"
    echo "Please create it from .env.example: cp .env.example .env.docker"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(docker ps -aqf "name=workspace")

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: workspace container is not running!"
    echo "Start it with: ./startmeup.sh or ./buildmeup.sh"
    exit 1
fi

echo "Entering workspace container as ivpldock user..."
docker exec --env-file .env.docker -it --user=ivpldock "$CONTAINER_ID" bash
