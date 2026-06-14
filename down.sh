#!/bin/bash
set -euo pipefail

# Stop and remove all containers, networks, and volumes
# Warning: This will remove all data in volumes!

# Check if .env.docker exists
if [ ! -f .env.docker ]; then
    echo "Error: .env.docker file not found!"
    echo "Please create it from .env.example: cp .env.example .env.docker"
    exit 1
fi

echo "Stopping and removing all containers, networks, and volumes..."
docker-compose --env-file .env.docker down -v

echo "All services stopped and cleaned up."
