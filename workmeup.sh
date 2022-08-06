#!/bin/bash
docker exec -it --user=ivpldock $(docker ps -aqf "name=ivpldock-workspace") bash
