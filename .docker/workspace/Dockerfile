#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#
# To edit the 'workspace' base Image, visit its repository on Github
#    https://github.com/Laradock/workspace
#
# To change its version, see the available Tags on the Docker Hub:
#    https://hub.docker.com/r/laradock/workspace/tags/
#
# Note: Base Image name format {image-tag}-{php-version}
#

ARG IVPLDOCK_PHP_VERSION
ARG BASE_IMAGE_TAG_PREFIX=latest
FROM laradock/workspace:${BASE_IMAGE_TAG_PREFIX}-${IVPLDOCK_PHP_VERSION}

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

ARG IVPLDOCK_PHP_VERSION

# Set Environment Variables
ENV DEBIAN_FRONTEND noninteractive

# Start as root
USER root

###########################################################################
# If you're in China, or you need to change sources, will be set CHANGE_SOURCE to true in .env.
###########################################################################

ARG CHANGE_SOURCE=false
RUN if [ ${CHANGE_SOURCE} = true ]; then \
    # Change application source from ubuntu.com to tuna.tsinghua.edu.cn source
    sed -i "s@http://.*archive.ubuntu.com@https://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list; \
    sed -i "s@http://.*security.ubuntu.com@https://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list; \
  fi;

###########################################################################
# Ivpldock non-root user:
###########################################################################

# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

# Set apt-get options:
ARG WORKSPACE_ALLOW_RELEASE_INFO_CHANGE=false
ENV WORKSPACE_ALLOW_RELEASE_INFO_CHANGE ${WORKSPACE_ALLOW_RELEASE_INFO_CHANGE}

# Step 1: Handle User and Directory Setup Safely
# CRITICAL: Ensure ivpldock user has the correct PUID/PGID to match host user
RUN set -e; \
    echo "Removing any user with UID=${PUID} and ivpldock user..."; \
    getent passwd ${PUID} | cut -d: -f1 | xargs -r userdel -rf; \
    userdel -rf ivpldock 2>/dev/null || true; \
    \
    echo "Removing ivpldock group and any group with GID=${PGID}..."; \
    getent group ${PGID} | grep -v "^ivpldock" | cut -d: -f1 | xargs -r groupdel || true; \
    groupdel ivpldock 2>/dev/null || true; \
    \
    echo "Creating fresh ivpldock with UID=${PUID} GID=${PGID}..."; \
    groupadd -g ${PGID} ivpldock; \
    useradd -l -m -u ${PUID} -g ${PGID} ivpldock; \
    \
    if getent group docker_env > /dev/null 2>&1; then \
      usermod -aG docker_env ivpldock; \
    fi; \
    \
    usermod -p "*" ivpldock -s /bin/bash; \
    mkdir -p /home/ivpldock; \
    chown -R ${PUID}:${PGID} /home/ivpldock; \
    \
    echo "✓ User setup complete. ivpldock: UID=$(id -u ivpldock) GID=$(id -g ivpldock)"

# Step 2: Volatile System Package Installation Block
RUN export DEBIAN_FRONTEND=noninteractive; \
    if [ ${WORKSPACE_ALLOW_RELEASE_INFO_CHANGE} = true ]; then \
      APT_GET_UPDATE_OPTIONS="--allow-releaseinfo-change"; \
    else \
      APT_GET_UPDATE_OPTIONS=""; \
    fi; \
    apt-get update ${APT_GET_UPDATE_OPTIONS} && \
    pecl channel-update pecl.php.net || true; \
    apt-get install -y --no-install-recommends apt-utils libzip-dev zip unzip nasm || echo "Core packages skipped"; \
    apt-get install -y --no-install-recommends php${IVPLDOCK_PHP_VERSION}-zip || echo "PHP zip extension skipped"; \
    apt-get install -y --no-install-recommends php${IVPLDOCK_PHP_VERSION}-intl || echo "PHP intl extension skipped"; \
    true

#
#--------------------------------------------------------------------------
# Optional Software's Installation
#--------------------------------------------------------------------------
#
# Optional Software's will only be installed if you set them to `true`
# in the `docker-compose.yml` before the build.
#

###########################################################################
# Set Timezone
###########################################################################

ARG TZ=UTC
ENV TZ ${TZ}

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

###########################################################################
# User Aliases
###########################################################################

USER root

COPY ./aliases.sh /root/aliases.sh
COPY ./aliases.sh /home/ivpldock/aliases.sh

RUN set -xe; \
    set +e; \
    if [ -f /root/aliases.sh ]; then sed -i 's/\r//' /root/aliases.sh; fi; \
    if [ -f /home/ivpldock/aliases.sh ]; then \
        sed -i 's/\r//' /home/ivpldock/aliases.sh; \
        if getent passwd ivpldock > /dev/null; then \
            chown ivpldock:ivpldock /home/ivpldock/aliases.sh; \
        fi; \
    fi; \
    set -e; \
    echo "" >> ~/.bashrc; \
    echo "# Load Custom Aliases" >> ~/.bashrc; \
    echo "source ~/aliases.sh" >> ~/.bashrc; \
    echo "" >> ~/.bashrc

USER ivpldock

RUN set -xe; \
    echo "" >> ~/.bashrc; \
    echo "# Load Custom Aliases" >> ~/.bashrc; \
    echo "source ~/aliases.sh" >> ~/.bashrc; \
    echo "" >> ~/.bashrc

###########################################################################
# Composer:
###########################################################################

USER root

# Add the composer.json
COPY ./composer.json /home/ivpldock/.composer/composer.json

# Add the auth.json for magento 2 credentials
COPY ./auth.json /home/ivpldock/.composer/auth.json

# Make sure that ~/.composer belongs to ivpldock
RUN chown -R ivpldock:ivpldock /home/ivpldock/.composer

# Export composer vendor path
RUN echo "" >> ~/.bashrc && \
    echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc

# Update composer
ARG COMPOSER_VERSION=2
ENV COMPOSER_VERSION ${COMPOSER_VERSION}
RUN set -eux; \
      if [ "$COMPOSER_VERSION" = "1" ] || [ "$COMPOSER_VERSION" = "2" ] || [ "$COMPOSER_VERSION" = "2.2" ]; then \
          composer self-update --${COMPOSER_VERSION}; \
      else \
          composer self-update ${COMPOSER_VERSION}; \
      fi

USER ivpldock

# Check if global install need to be ran
ARG COMPOSER_GLOBAL_INSTALL=false
ENV COMPOSER_GLOBAL_INSTALL ${COMPOSER_GLOBAL_INSTALL}

RUN if [ ${COMPOSER_GLOBAL_INSTALL} = true ]; then \
    # run the install
    composer global install \
;fi

# Check if auth file is disabled
ARG COMPOSER_AUTH_JSON=false
ENV COMPOSER_AUTH_JSON ${COMPOSER_AUTH_JSON}

RUN if [ ${COMPOSER_AUTH_JSON} = false ]; then \
    # remove the file
    rm /home/ivpldock/.composer/auth.json \
;fi

ARG COMPOSER_REPO_PACKAGIST
ENV COMPOSER_REPO_PACKAGIST ${COMPOSER_REPO_PACKAGIST}

RUN if [ ${COMPOSER_REPO_PACKAGIST} ]; then \
    composer config -g repo.packagist composer ${COMPOSER_REPO_PACKAGIST} \
;fi

# Export composer vendor path
RUN echo "" >> ~/.bashrc && \
    echo 'export PATH="~/.composer/vendor/bin:$PATH"' >> ~/.bashrc

###########################################################################
# Non-root user : PHPUnit path
###########################################################################

# add ./vendor/bin to non-root user's bashrc (needed for phpunit)
USER ivpldock

RUN echo "" >> ~/.bashrc && \
    echo 'export PATH="/var/www/vendor/bin:$PATH"' >> ~/.bashrc

###########################################################################
# Crontab
###########################################################################

USER root

COPY ./crontab /etc/cron.d

RUN chmod -R 644 /etc/cron.d

###########################################################################
# Certificate Authorities
###########################################################################

USER root

COPY ./ca-certificates/* /usr/local/share/ca-certificates/
RUN update-ca-certificates

###########################################################################
# Drush:
###########################################################################

USER root

ARG INSTALL_DRUSH=false
ARG DRUSH_VERSION
ENV DRUSH_VERSION ${DRUSH_VERSION}

RUN if [ ${INSTALL_DRUSH} = true ]; then \
    apt-get -qq -y install mysql-client && \
    # Install Drush with the phar file.
    curl -fsSL -o /usr/local/bin/drush https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar | bash && \
    chmod +x /usr/local/bin/drush && \
    drush core-status \
;fi

###########################################################################
# WP CLI:
###########################################################################

USER root

ARG INSTALL_WP_CLI=false

RUN if [ ${INSTALL_WP_CLI} = true ]; then \
    curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar | bash && \
    chmod +x /usr/local/bin/wp \
;fi

###########################################################################
USER root

ARG INSTALL_BZ2=false
ARG INSTALL_GMP=false
ARG INSTALL_GNUPG=false
ARG INSTALL_SSH2=false
ARG INSTALL_SOAP=false
ARG INSTALL_XSL=false
ARG PHP_VERSION=${IVPLDOCK_PHP_VERSION}

RUN set -eux; \
    if [ ${INSTALL_BZ2} = true ]; then \
      apt-get -yqq install php${IVPLDOCK_PHP_VERSION}-bz2; \
    fi; \
    if [ ${INSTALL_GMP} = true ]; then \
      apt-get -yqq install php${IVPLDOCK_PHP_VERSION}-gmp; \
    fi; \
    if [ ${INSTALL_GNUPG} = true ]; then \
        apt-get -yqq install php${IVPLDOCK_PHP_VERSION}-gnupg; \
    fi; \
    if [ ${INSTALL_SSH2} = true ]; then \
      apt-get -yqq install libssh2-1-dev php${IVPLDOCK_PHP_VERSION}-ssh2; \
    fi; \
    if [ ${INSTALL_SOAP} = true ]; then \
      apt-get -yqq install libxml2-dev php${IVPLDOCK_PHP_VERSION}-soap; \
    fi; \
    if [ ${INSTALL_XSL} = true ]; then \
      apt-get -yqq install libxslt-dev php${IVPLDOCK_PHP_VERSION}-xsl; \
    fi

###########################################################################

ARG INSTALL_LDAP=false
ARG INSTALL_SMB=false
ARG INSTALL_IMAP=false
ARG INSTALL_SUBVERSION=false

RUN set -eux; \
    if [ ${INSTALL_LDAP} = true ]; then \
        apt-get install -yqq libldap2-dev php${IVPLDOCK_PHP_VERSION}-ldap; \
    fi; \
    if [ ${INSTALL_SMB} = true ]; then \
        apt-get install -yqq smbclient libsmbclient-dev php${IVPLDOCK_PHP_VERSION}-smbclient coreutils && \
        if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
            pecl install smbclient; \
        else \
            pecl install smbclient-1.1.2; \
        fi && \
        echo "extension=smbclient.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/cli/php.ini; \
    fi; \
    if [ ${INSTALL_IMAP} = true ]; then \
        apt-get install -yqq php${IVPLDOCK_PHP_VERSION}-imap; \
    fi; \
    if [ ${INSTALL_SUBVERSION} = true ]; then \
        apt-get install -yqq subversion; \
    fi

###########################################################################
# xDebug:
###########################################################################

USER root

ARG INSTALL_XDEBUG=false
ARG XDEBUG_PORT=9003

RUN if [ ${INSTALL_XDEBUG} = true ]; then \
  apt-get install -yqq pkg-config php-xml php${IVPLDOCK_PHP_VERSION}-xml && \
  if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ] || { [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ] && { [ $(php -r "echo PHP_MINOR_VERSION;") = "4" ] || [ $(php -r "echo PHP_MINOR_VERSION;") = "3" ] ;} ;}; then \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
      pecl install xdebug-3.5.0; \
    else \
      pecl install xdebug-3.1.6; \
    fi; \
  else \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      pecl install xdebug-2.5.5; \
    else \
      if [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ]; then \
        pecl install xdebug-2.9.0; \
      else \
        pecl install xdebug-2.9.8; \
      fi \
    fi \
  fi && \
  echo "zend_extension=xdebug.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-xdebug.ini \
;fi

# ADD for REMOTE debugging
COPY ./xdebug.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini

RUN if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ] || { [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ] && { [ $(php -r "echo PHP_MINOR_VERSION;") = "4" ] || [ $(php -r "echo PHP_MINOR_VERSION;") = "3" ] ;} ;}; then \
  sed -i "s/xdebug.remote_host=/xdebug.client_host=/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_connect_back=0/xdebug.discover_client_host=false/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_port=9000/xdebug.client_port=${XDEBUG_PORT}/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.profiler_enable=0/; xdebug.profiler_enable=0/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.profiler_output_dir=/xdebug.output_dir=/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_mode=req/; xdebug.remote_mode=req/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_autostart=0/xdebug.start_with_request=yes/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_enable=0/xdebug.mode=debug/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini \
;else \
  sed -i "s/xdebug.remote_autostart=0/xdebug.remote_autostart=1/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_enable=0/xdebug.remote_enable=1/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini \
;fi
RUN sed -i "s/xdebug.cli_color=0/xdebug.cli_color=1/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini

###########################################################################
# pcov:
###########################################################################

USER root

ARG INSTALL_PCOV=false

RUN if [ ${INSTALL_PCOV} = true ]; then \
  if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ] || { [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ] && [ $(php -r "echo PHP_MINOR_VERSION;") != "0" ]; }; then \
    pecl install pcov && \
    echo "extension=pcov.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/cli/php.ini && \
    echo "pcov.enabled" >> /etc/php/${IVPLDOCK_PHP_VERSION}/cli/php.ini \
  ;fi \
;fi

###########################################################################
# Phpdbg:
###########################################################################

USER root

ARG INSTALL_PHPDBG=false

RUN if [ ${INSTALL_PHPDBG} = true ]; then \
    apt-get install -y --force-yes php${IVPLDOCK_PHP_VERSION}-phpdbg \
;fi

###########################################################################
# Blackfire:
###########################################################################

ARG INSTALL_BLACKFIRE=false
ARG BLACKFIRE_CLIENT_ID
ENV BLACKFIRE_CLIENT_ID ${BLACKFIRE_CLIENT_ID}
ARG BLACKFIRE_CLIENT_TOKEN
ENV BLACKFIRE_CLIENT_TOKEN ${BLACKFIRE_CLIENT_TOKEN}

RUN if [ ${INSTALL_XDEBUG} = false -a ${INSTALL_BLACKFIRE} = true ]; then \
    curl -L https://packages.blackfire.io/gpg.key | apt-key add - && \
    echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list && \
    apt-get update -yqq && \
    apt-get install blackfire-agent \
;fi

###########################################################################
# ssh:
###########################################################################

ARG INSTALL_WORKSPACE_SSH=false

COPY insecure_id_rsa /tmp/id_rsa
COPY insecure_id_rsa.pub /tmp/id_rsa.pub

RUN if [ ${INSTALL_WORKSPACE_SSH} = true ]; then \
    rm -f /etc/service/sshd/down && \
    cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys \
        && cat /tmp/id_rsa.pub >> /root/.ssh/id_rsa.pub \
        && cat /tmp/id_rsa >> /root/.ssh/id_rsa \
        && rm -f /tmp/id_rsa* \
        && chmod 644 /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub \
    && chmod 400 /root/.ssh/id_rsa \
    && cp -rf /root/.ssh /home/ivpldock \
    && chown -R ivpldock:ivpldock /home/ivpldock/.ssh \
;fi

###########################################################################
# MongoDB:
###########################################################################

ARG INSTALL_MONGO=false

RUN if [ ${INSTALL_MONGO} = true ]; then \
    apt-get install -yqq pkg-config && \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      pecl install mongo; \
      echo "extension=mongo.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/mongo.ini; \
      ln -s /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/mongo.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/30-mongo.ini; \
      php -m | grep -oiE '^mongo$'; \
    else \
      if [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ]; then \
        if [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ] || [ $(php -r "echo PHP_MINOR_VERSION;") = "1" ]; then \
          pecl install mongodb-1.9.2; \
        else \
          if [ $(php -r "echo PHP_MINOR_VERSION;") = "4" ]; then \
            pecl install mongodb-1.20.1; \
          else \
            pecl install mongodb-1.16.2; \
          fi; \
        fi; \
      else \
        if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ] && [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ]; then \
            pecl install mongodb-1.20.1; \
        else \
            pecl install mongodb; \
        fi; \
      fi; \
      echo "extension=mongodb.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/mongodb.ini; \
      ln -s /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/mongodb.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/30-mongodb.ini; \
      php -m | grep -oiE '^mongodb$'; \
    fi; \
fi

###########################################################################
# AMQP:
###########################################################################

ARG INSTALL_AMQP=false

RUN if [ ${INSTALL_AMQP} = true ]; then \
    apt-get install -yqq librabbitmq-dev && \
    if [ ${IVPLDOCK_PHP_VERSION} = "7.3" ] \
      || [ ${IVPLDOCK_PHP_VERSION} = "7.2" ] \
      || [ ${IVPLDOCK_PHP_VERSION} = "7.1" ] \
      || [ ${IVPLDOCK_PHP_VERSION} = "7.0" ] \
      || [ ${IVPLDOCK_PHP_VERSION} = "5.6" ]; then \
      printf "\n" | pecl install amqp-1.11.0; \
    else \
      printf "\n" | pecl install amqp; \
    fi && \
    echo "extension=amqp.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/amqp.ini && \
    ln -s /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/amqp.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/30-amqp.ini && \
    php -m | grep -oiE '^amqp$' \
;fi

###########################################################################
# CASSANDRA:
###########################################################################

ARG INSTALL_CASSANDRA=false

RUN if [ ${INSTALL_CASSANDRA} = true ]; then \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
      echo "PHP Driver for Cassandra is not supported for PHP 8.0."; \
    else \
      apt-get install libgmp-dev -yqq && \
      curl https://downloads.datastax.com/cpp-driver/ubuntu/18.04/dependencies/libuv/v1.35.0/libuv1-dev_1.35.0-1_amd64.deb -o libuv1-dev.deb && \
      curl https://downloads.datastax.com/cpp-driver/ubuntu/18.04/dependencies/libuv/v1.35.0/libuv1_1.35.0-1_amd64.deb -o libuv1.deb && \
      curl https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.16.0/cassandra-cpp-driver-dev_2.16.0-1_amd64.deb -o cassandra-cpp-driver-dev.deb && \
      curl https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.16.0/cassandra-cpp-driver_2.16.0-1_amd64.deb -o cassandra-cpp-driver.deb && \
      dpkg -i libuv1.deb && \
      dpkg -i libuv1-dev.deb && \
      dpkg -i cassandra-cpp-driver.deb && \
      dpkg -i cassandra-cpp-driver-dev.deb && \
      rm libuv1.deb libuv1-dev.deb cassandra-cpp-driver-dev.deb cassandra-cpp-driver.deb && \
      cd /usr/src && \
      git clone https://github.com/datastax/php-driver.git && \
      cd /usr/src/php-driver/ext && \
      phpize && \
      mkdir /usr/src/php-driver/build && \
      cd /usr/src/php-driver/build && \
      ../ext/configure > /dev/null && \
      make clean >/dev/null && \
      make >/dev/null 2>&1 && \
      make install && \
      echo "extension=cassandra.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/cassandra.ini && \
      ln -s /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/cassandra.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/30-cassandra.ini; \
    fi \
;fi

###########################################################################
# Gearman:
###########################################################################

ARG INSTALL_GEARMAN=false

RUN if [ ${INSTALL_GEARMAN} = true ]; then \
    add-apt-repository -y ppa:ondrej/pkg-gearman && \
    apt-get update && \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ]; then \
      apt-get install php${IVPLDOCK_PHP_VERSION}-gearman -y; \
    else \
      apt-get install php-gearman -y; \
    fi \
;fi

###########################################################################
# PHP REDIS EXTENSION
###########################################################################

ARG INSTALL_PHPREDIS=false

RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    apt-get update --allow-releaseinfo-change \
    && apt-get install -yqq php${IVPLDOCK_PHP_VERSION}-redis \
;fi

###########################################################################
# Swoole EXTENSION
###########################################################################

ARG INSTALL_SWOOLE=false

RUN set -eux; \
    if [ ${INSTALL_SWOOLE} = true ]; then \
      if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        echo '' | pecl -q install swoole-2.0.10; \
      elif [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ] && [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ]; then \
        echo '' | pecl -q install swoole-4.3.5; \
      elif [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ] && [ $(php -r "echo PHP_MINOR_VERSION;") = "1" ]; then \
        echo '' | pecl -q install swoole-4.5.11; \
      elif [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ]; then \
        echo '' | pecl -q install swoole-4.8.12; \
      elif [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ] && [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ]; then \
        echo '' | pecl -q install swoole-5.1.2; \
      else \
        apt-get install -yqq libbrotli-dev && \
        echo '' | pecl -q install swoole; \
      fi; \
      echo "extension=swoole.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/swoole.ini; \
      ln -s /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/swoole.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-swoole.ini; \
      php -m | grep -q 'swoole'; \
    fi

###########################################################################
# xlswriter:
###########################################################################

ARG INSTALL_XLSWRITER=false

RUN set -eux; \
    if [ ${INSTALL_XLSWRITER} = true ]; then \
      if [ $(php -r "echo PHP_MAJOR_VERSION;") != "5" ]; then \
        echo '' | pecl -q install xlswriter && \
        echo "extension=xlswriter.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/xlswriter.ini && \
        ln -s /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/xlswriter.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-xlswriter.ini; \
      fi \
    fi

###########################################################################
# Node / NVM:
###########################################################################

# Install build dependencies required for Node compilation
USER root

RUN apt-get update && \
    apt-get install -yqq curl && \
    true

USER ivpldock

# Check if NVM needs to be installed
ARG NODE_VERSION=node
ENV NODE_VERSION ${NODE_VERSION}
ARG INSTALL_NODE=false
ARG INSTALL_NPM_GULP=false
ARG INSTALL_NPM_BOWER=false
ARG INSTALL_NPM_VUE_CLI=false
ARG INSTALL_NPM_ANGULAR_CLI=false
ARG INSTALL_NPM_CHECK_UPDATES_CLI=false
ARG NPM_REGISTRY
ENV NPM_REGISTRY ${NPM_REGISTRY}
ARG NPM_FETCH_RETRIES
ENV NPM_FETCH_RETRIES ${NPM_FETCH_RETRIES}
ARG NPM_FETCH_RETRY_FACTOR
ENV NPM_FETCH_RETRY_FACTOR ${NPM_FETCH_RETRY_FACTOR}
ARG NPM_FETCH_RETRY_MINTIMEOUT
ENV NPM_FETCH_RETRY_MINTIMEOUT ${NPM_FETCH_RETRY_MINTIMEOUT}
ARG NPM_FETCH_RETRY_MAXTIMEOUT
ENV NPM_FETCH_RETRY_MAXTIMEOUT ${NPM_FETCH_RETRY_MAXTIMEOUT}

ENV NVM_DIR /home/ivpldock/.nvm
ARG NVM_NODEJS_ORG_MIRROR
ENV NVM_NODEJS_ORG_MIRROR ${NVM_NODEJS_ORG_MIRROR}

# CRITICAL: Install NVM if INSTALL_NODE is true. Base image does not include NVM.
RUN if [ ${INSTALL_NODE} = true ]; then \
    echo "Installing NVM..." && \
    mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    echo "NVM installed successfully. Installing Node versions..." && \
    for version in 18 20 22 24; do \
        echo "Installing Node $version..." && \
        nvm install $version && \
        npm install -g npm@latest; \
    done && \
    nvm use 22 && \
    nvm alias default 22 && \
    echo "Node setup complete. Creating symlinks for global access..." && \
    NODE_MODS_DIR="$(nvm which default | sed -r 's/\/bin\/node//')/lib/node_modules" && \
    ln -sf "$(nvm which default)" /usr/local/bin/node && \
    ln -sf "$(nvm which default | sed -r 's/\/bin\/node//')/bin/npm" /usr/local/bin/npm && \
    ln -sf "$(nvm which default | sed -r 's/\/bin\/node//')/bin/npx" /usr/local/bin/npx && \
    npm --version && \
    node --version && \
    echo "" >> /home/ivpldock/.bashrc && \
    echo "# Load NVM" >> /home/ivpldock/.bashrc && \
    echo "export NVM_DIR=\"/home/ivpldock/.nvm\"" >> /home/ivpldock/.bashrc && \
    echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> /home/ivpldock/.bashrc && \
    echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"" >> /home/ivpldock/.bashrc; \
fi; \
true

RUN if [ ${NPM_REGISTRY} ]; then \
    . ~/.bashrc && npm config set registry ${NPM_REGISTRY} \
;fi

# Mount .npmrc into home folder
COPY ./.npmrc /root/.npmrc
COPY ./.npmrc /home/ivpldock/.npmrc

###########################################################################
# YARN:
###########################################################################

USER ivpldock

ARG INSTALL_YARN=false
ARG YARN_VERSION=latest
ENV YARN_VERSION ${YARN_VERSION}

RUN if [ ${INSTALL_YARN} = true ]; then \
    . "$NVM_DIR/nvm.sh" && \
    echo "Setting up Yarn..." && \
    corepack enable && \
    if [ "${YARN_VERSION}" = "latest" ]; then \
        corepack prepare yarn@stable --activate; \
    else \
        corepack prepare yarn@${YARN_VERSION} --activate; \
    fi && \
    yarn --version; \
fi; \
true

# Make yarn/npm/node available globally (as root and all users) by creating symlinks with proper permissions
USER root

RUN if [ ${INSTALL_NODE} = true ]; then \
    NODE_PATH="/home/ivpldock/.nvm/versions/node/$(ls -t /home/ivpldock/.nvm/versions/node | head -1)/bin" && \
    ln -sf "$NODE_PATH/node" /usr/local/bin/node && \
    ln -sf "$NODE_PATH/npm" /usr/local/bin/npm && \
    ln -sf "$NODE_PATH/npx" /usr/local/bin/npx && \
    chmod +x /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx && \
    node --version && \
    npm --version; \
fi

RUN if [ ${INSTALL_YARN} = true ]; then \
    . "/home/ivpldock/.nvm/nvm.sh" && \
    YARN_BIN=$(which yarn || echo "") && \
    if [ -n "$YARN_BIN" ]; then \
        ln -sf "$YARN_BIN" /usr/local/bin/yarn && \
        chmod +x /usr/local/bin/yarn && \
        /usr/local/bin/yarn --version; \
    fi; \
fi

###########################################################################
# Headless Chromium:
###########################################################################

USER root

ARG INSTALL_CHROMIUM=false

# Ubuntu 24.04's own `chromium` / `chromium-browser` apt packages are
# snap-transition stubs: installing them pulls in snapd, which does not run
# inside a container. Install Google's official Chrome .deb repo instead (a
# real package, security-updated through `apt-get upgrade`) and expose the
# binary under the `chromium` / `chromium-browser` / `chrome` names that
# browser tooling looks for. amd64 only — Google publishes no arm64 .deb.
#
# Runtime note: in a container Chrome needs `--no-sandbox` (no user
# namespaces), and `--headless=new --disable-dev-shm-usage` for CI. Callers
# pass those themselves; we don't wrap them in so the binary stays generic.
RUN if [ ${INSTALL_CHROMIUM} = true ]; then \
      set -eux; \
      apt-get update; \
      apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
      install -d -m 0755 /etc/apt/keyrings; \
      curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg; \
      echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list; \
      apt-get update; \
      apt-get install -y --no-install-recommends google-chrome-stable; \
      ln -sf /usr/bin/google-chrome-stable /usr/local/bin/chrome; \
      ln -sf /usr/bin/google-chrome-stable /usr/local/bin/chromium; \
      ln -sf /usr/bin/google-chrome-stable /usr/local/bin/chromium-browser; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*; \
      chromium --version; \
    fi; \
    true

# Let test runners that autodetect the browser (karma, puppeteer,
# lighthouse, symfony/panther, ...) find it without extra config.
ENV CHROME_BIN=/usr/local/bin/chromium

###########################################################################
# Puppeteer (Node launcher for Spatie Browsershot / headless Chrome):
###########################################################################

USER root

ARG INSTALL_PUPPETEER=false

# Spatie Browsershot does not talk to Chrome directly: it runs
# `node vendor/spatie/browsershot/bin/browser.cjs`, and that script does
# `require('puppeteer')`. The google-chrome-stable binary from the
# INSTALL_CHROMIUM step above is necessary but NOT sufficient — without the
# `puppeteer` npm package on the Node resolution path, every Browsershot
# call fails with `Error: Cannot find module 'puppeteer'` and callers are
# forced to skip PDF/screenshot tests.
#
# Install it once, globally, under the standard /usr/local prefix (a real
# root-owned dir — no writes into ivpldock's nvm home tree) and put that
# dir on NODE_PATH below. nvm-built Node does not carry /usr/local in its
# GLOBAL_FOLDERS list, so the explicit NODE_PATH is what makes
# `require('puppeteer')` resolve from any project with no per-project
# `npm install`, including from PHP shelling out to `node` in the PHPUnit
# suite (which never sources ivpldock's .bashrc).
#
# NODE_PATH alone is not enough for Spatie Browsershot specifically: its
# `browser.cjs` launcher spawns node with NODE_PATH overridden to the live
# output of `npm root -g`, clobbering whatever NODE_PATH the container
# already had. Since /usr/local/bin/npm is a symlink into nvm's own node
# install (see the Node/NVM section above), `npm root -g` without an
# explicit prefix reports nvm's global dir (e.g.
# ~/.nvm/versions/node/vX/lib/node_modules), not /usr/local — so Browsershot
# would still fail with `Cannot find module 'puppeteer'` even though the
# package is installed and NODE_PATH is set correctly at the container
# level. NPM_CONFIG_PREFIX pins npm's global prefix to /usr/local for every
# npm/node invocation (env var beats .npmrc/nvm defaults), so `npm root -g`
# — however it's invoked — always agrees with where puppeteer actually is.
#
# Puppeteer's own bundled-Chromium download is skipped — we point it at the
# Chrome already installed above so the image carries exactly one browser.
# `puppeteer.launch()` with no executablePath honours PUPPETEER_EXECUTABLE_PATH.
ENV PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/local/bin/chromium \
    NODE_PATH=/usr/local/lib/node_modules \
    NPM_CONFIG_PREFIX=/usr/local
RUN if [ ${INSTALL_PUPPETEER} = true ]; then \
      set -eux; \
      /usr/local/bin/npm install -g --prefix=/usr/local puppeteer; \
      NODE_PATH=/usr/local/lib/node_modules node -e "require.resolve('puppeteer')"; \
      test "$(npm root -g)" = "/usr/local/lib/node_modules"; \
      /usr/local/bin/chromium --version; \
    fi; \
    true

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

USER root

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -f /var/log/lastlog /var/log/faillog

WORKDIR /var/www/projects
