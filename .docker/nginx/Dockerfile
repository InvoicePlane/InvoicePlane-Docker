FROM nginx:alpine

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

COPY nginx/nginx.conf /etc/nginx/

RUN apk update \
    && apk upgrade \
    && apk add --no-cache bash

RUN apk add --no-cache curl

RUN set -x ; \
    addgroup -g 82 -S www-data ; \
    adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

ARG PHP_UPSTREAM_CONTAINER=php-fpm
ARG PHP_UPSTREAM_PORT=9000

# Create 'messages' file used from 'logrotate'
RUN touch /var/log/messages

# Set upstream conf and remove the default conf
RUN echo "upstream php-upstream { server ${PHP_UPSTREAM_CONTAINER}:${PHP_UPSTREAM_PORT}; }" > /etc/nginx/conf.d/upstream.conf \
    && rm /etc/nginx/conf.d/default.conf

ADD nginx/startup.sh /opt/startup.sh
RUN sed -i 's/\r//g' /opt/startup.sh

# Add InvoicePlane banner to bash profile
COPY invoiceplane-banner.sh /root/invoiceplane-banner.sh
RUN sed -i 's/\r//g' /root/invoiceplane-banner.sh
RUN chmod +x /root/invoiceplane-banner.sh && \
    echo "" >> /root/.bashrc && \
    echo "# Set container type for banner" >> /root/.bashrc && \
    echo "export CONTAINER_TYPE='Nginx Container'" >> /root/.bashrc && \
    echo "# Load InvoicePlane Banner" >> /root/.bashrc && \
    echo "if [ -f ~/invoiceplane-banner.sh ]; then" >> /root/.bashrc && \
    echo "    source ~/invoiceplane-banner.sh" >> /root/.bashrc && \
    echo "fi" >> /root/.bashrc && \
    # Also add banner for www-data user \
    mkdir -p /home/www-data && \
    cp /root/invoiceplane-banner.sh /home/www-data/invoiceplane-banner.sh && \
    chown www-data:www-data /home/www-data/invoiceplane-banner.sh && \
    chmod +x /home/www-data/invoiceplane-banner.sh && \
    touch /home/www-data/.bashrc && \
    chown www-data:www-data /home/www-data/.bashrc && \
    echo "" >> /home/www-data/.bashrc && \
    echo "# Set container type for banner" >> /home/www-data/.bashrc && \
    echo "export CONTAINER_TYPE='Nginx Container'" >> /home/www-data/.bashrc && \
    echo "# Load InvoicePlane Banner" >> /home/www-data/.bashrc && \
    echo "if [ -f ~/invoiceplane-banner.sh ]; then" >> /home/www-data/.bashrc && \
    echo "    source ~/invoiceplane-banner.sh" >> /home/www-data/.bashrc && \
    echo "fi" >> /home/www-data/.bashrc

CMD ["/bin/bash", "/opt/startup.sh"]

EXPOSE 80 81 443
