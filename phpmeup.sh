#!/bin/bash
set -euo pipefail

# Enter the php-fpm container with bash shell

# Check if .env.docker exists
if [ ! -f .env.docker ]; then
    echo "Error: .env.docker file not found!"
    echo "Please create it from .env.example: cp .env.example .env.docker"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(docker ps -aqf "name=php-fpm")

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: php-fpm container is not running!"
    echo "Start it with: ./startmeup.sh or ./buildmeup.sh"
    exit 1
fi

echo "Entering php-fpm container..."
docker exec --env-file=.env.docker -it "$CONTAINER_ID" bash
