#!/bin/bash
docker compose --env-file .env.docker exec --user=ivpldock workspace bash
