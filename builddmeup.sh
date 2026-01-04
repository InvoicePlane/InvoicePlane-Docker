#!/bin/bash
set -euo pipefail

# Build and start all services with docker-compose in detached mode
# This script will build images and start containers in the background

# Check if .env.docker exists
if [ ! -f .env.docker ]; then
    echo "Error: .env.docker file not found!"
    echo "Please create it from .env.example: cp .env.example .env.docker"
    exit 1
fi

echo "Building and starting services in detached mode..."
docker-compose --env-file .env.docker up \
    beanstalkd \
    beanstalkd-console \
    mariadb \
    nginx \
    php-fpm \
    php-worker \
    phpmyadmin \
    workspace \
    --build -d

echo "Services started successfully in the background."
echo "Use 'docker-compose --env-file .env.docker ps' to see running containers."
