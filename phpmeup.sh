#!/bin/bash
docker exec --env-file=.env.docker -it --user=ivpldock $(docker ps -aqf "name=php-fpm") bash
