#!/bin/sh

if [ -n "$REDIS_PASSWORD" ]; then
    exec redis-server --requirepass "$REDIS_PASSWORD"
fi

exec redis-server