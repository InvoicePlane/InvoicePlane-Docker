#!/bin/bash
set -e

check_and_create_volumes() {
  VOLUME_NAME=$1
  if [ -z "$(docker volume ls -q -f name=^${VOLUME_NAME}$)" ]; then
    echo "External volume '${VOLUME_NAME}' not found. Creating it now..."
    docker volume create "${VOLUME_NAME}"
  else
    echo "External volume '${VOLUME_NAME}' already exists."
  fi
}

check_and_create_volumes ivpldock_redis
check_and_create_volumes ivpldock_mariadb

COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 \
docker-compose --env-file .env.docker up \
  --build \
  mariadb \
  nginx \
  php-fpm \
  #php-worker \
  phpmyadmin \
  redis \
  workspace
