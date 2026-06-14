#!/bin/bash
docker exec --env-file .env.docker -it $(docker ps -aqf "name=worker") sh
