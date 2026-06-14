#!/bin/bash

echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

sysctl -w net.core.somaxconn=512
sysctl vm.overcommit_memory=1
redis-server /usr/local/etc/redis/redis.conf --bind 0.0.0.0
