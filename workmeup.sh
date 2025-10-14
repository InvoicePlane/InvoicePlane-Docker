#!/bin/bash
docker exec --env-file .env.docker -it --user=devdock $(docker ps -aqf "name=workspace") bash
