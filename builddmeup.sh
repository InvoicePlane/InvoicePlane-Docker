#!/bin/bash
docker-compose --env-file .env.docker up beanstalkd beanstalkd-console mariadb nginx php-fpm php-worker phpmyadmin workspace --build -d

