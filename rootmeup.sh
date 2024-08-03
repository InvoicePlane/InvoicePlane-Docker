#!/bin/bash
# shellcheck disable=SC2046
docker exec --env-file .env.docker -it $(docker ps -aqf "name=workspace") bash
