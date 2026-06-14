#!/bin/bash
set -euo pipefail

# Start all services with docker-compose (without building)
# This script will start containers in foreground mode

# Check if .env.docker exists
if [ ! -f .env.docker ]; then
    echo "Error: .env.docker file not found!"
    echo "Please create it from .env.example: cp .env.example .env.docker"
    exit 1
fi

echo "Starting services..."
docker-compose --env-file .env.docker up \
    beanstalkd \
    beanstalkd-console \
    mariadb \
    nginx \
    php-fpm \
    php-worker \
    phpmyadmin \
    redis \
    workspace

echo "Services stopped."
