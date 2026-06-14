FROM redis:latest

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

COPY start-redis.sh /usr/local/bin/start-redis.sh

RUN chmod +x /usr/local/bin/start-redis.sh

VOLUME /data

EXPOSE 6379

CMD ["start-redis.sh"]