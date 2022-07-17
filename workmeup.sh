#!/bin/bash
docker exec -it --user=ivpldock $(docker ps -aqf "name=workspace") bash
