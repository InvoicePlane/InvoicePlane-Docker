#!/bin/bash
docker exec --env-file .env.docker -it --user=ivpldock $(docker ps -aqf "name=redis") bash
