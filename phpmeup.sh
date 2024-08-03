#!/bin/bash
# shellcheck disable=SC2046
docker exec --env-file=.env.docker -it --user=ivpldock $(docker ps -aqf "name=php-fpm") bash
