FROM phpmyadmin

LABEL maintainer="Bo-Yi Wu <appleboy.tw@gmail.com>"

COPY config.user.inc.php /etc/phpmyadmin/config.user.inc.php

#
# Install custom theme
#
COPY nord-theme /var/www/html/themes/nord-theme

#
# Install custom fonts
#
COPY fonts /var/www/html/themes/nord-theme/fonts

#
# Override template
#
COPY header.twig /var/www/html/templates/header.twig

#
# Extra CSS
#
COPY metro-font-override.css /var/www/html/themes/nord-theme/css/metro-font-override.css

# Add volume for sessions to allow session persistence
VOLUME /sessions

# We expose phpMyAdmin on port 80
EXPOSE 80