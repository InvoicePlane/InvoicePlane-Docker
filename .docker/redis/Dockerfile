FROM redis:alpine
WORKDIR /redis
COPY redis/redis.conf /usr/local/etc/redis/redis.conf
COPY redis/init.sh ./
RUN chmod +x init.sh
