#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#
# To edit the 'workspace' base Image, visit its repository on Github
#    https://github.com/Laradock/workspace
#
# To change its version, see the available Tags on the Docker Hub:
#    https://hub.docker.com/r/ivpldock/workspace/tags/
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

# Set up default environment variables, sourcing from .env where possible
ARG IVPLDOCK_USER
ARG WORKSPACE_WORKDIR
ARG TIMEZONE
ARG NODE_VERSION
ARG XDEBUG_PORT
ARG WORKSPACE_VITE_PORT

###########################################################################
# Laradock non-root user:
###########################################################################

# Add a non-root user to prevent files being created with root permissions on host machine.
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=${TIMEZONE:-UTC} \
    PUID=1000 \
    PGID=1000 \
    IVPLDOCK_USER=${IVPLDOCK_USER:-ivpldock} \
    WORKDIR=${WORKSPACE_WORKDIR:-/var/www/projects} \
    NODE_VERSION=${NODE_VERSION:-18} \
    XDEBUG_PORT=${XDEBUG_PORT:-9003} \
    VITE_PORT=${WORKSPACE_VITE_PORT:-5173}

# always run apt update when start and after add new source list, then clean up at end.
RUN set -xe; \
    apt-get update -yqq && \
    (pecl channel-update pecl.php.net || true) && \
    # Ensure docker_env group exists for workspace user
    (groupadd docker_env || true) && \
    # Ensure ivpldock group exists: try requested PGID first, then fall back to default GID
    if ! getent group ivpldock > /dev/null; then \
        if ! groupadd -g ${PGID} ivpldock 2>/dev/null; then \
            groupadd ivpldock; \
        fi; \
    fi && \
    # Ensure ivpldock user exists and is member of docker_env; do not rename existing system users
    if ! id -u ivpldock > /dev/null 2>&1; then \
        useradd -u ${PUID} -g ivpldock -m ivpldock -G docker_env; \
    else \
        usermod -aG docker_env ivpldock; \
    fi && \
    usermod -p "*" ivpldock -s /bin/bash && \
    apt-get install -yqq \
      apt-utils \
      #
      #--------------------------------------------------------------------------
      # Mandatory Software's Installation
      #--------------------------------------------------------------------------
      #
      # Mandatory Software's such as ("php-cli", "git", "vim", ....) are
      # installed on the base image 'ivpldock/workspace' image. If you want
      # to add more Software's or remove existing one, you need to edit the
      # base image (https://github.com/Laradock/workspace).
      #
      # next lines are here because there is no auto build on dockerhub see https://github.com/ivpldock/ivpldock/pull/1903#issuecomment-463142846
      libzip-dev zip unzip \
      # nasm
      nasm && \
      # Install the zip extension if available (base image already includes it, but try anyway)
      (apt-get install -yqq php${IVPLDOCK_PHP_VERSION}-zip || true) && \
      php -m | grep -q 'zip'

#
#--------------------------------------------------------------------------
# Optional Software's Installation
#--------------------------------------------------------------------------
#
# Optional Software's will only be installed if you set them to `true`
# in the `docker-compose.yml` before the build.
# Example:
#   - INSTALL_NODE=false
#   - ...
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

COPY workspace/aliases.sh /root/aliases.sh
COPY workspace/aliases.sh /home/ivpldock/aliases.sh
COPY invoiceplane-banner.sh /root/invoiceplane-banner.sh
COPY invoiceplane-banner.sh /home/ivpldock/invoiceplane-banner.sh

RUN sed -i 's/\r//' /root/aliases.sh && \
    sed -i 's/\r//' /home/ivpldock/aliases.sh && \
    sed -i 's/\r//' /root/invoiceplane-banner.sh && \
    sed -i 's/\r//' /home/ivpldock/invoiceplane-banner.sh && \
    chown ivpldock:ivpldock /home/ivpldock/aliases.sh && \
    chown ivpldock:ivpldock /home/ivpldock/invoiceplane-banner.sh && \
    chmod +x /root/invoiceplane-banner.sh && \
    chmod +x /home/ivpldock/invoiceplane-banner.sh && \
    echo "" >> ~/.bashrc && \
    echo "# Set container type for banner" >> ~/.bashrc && \
    echo "export CONTAINER_TYPE='Workspace Container'" >> ~/.bashrc && \
    echo "# Load InvoicePlane Banner" >> ~/.bashrc && \
    echo "if [ -f ~/invoiceplane-banner.sh ]; then" >> ~/.bashrc && \
    echo "    source ~/invoiceplane-banner.sh" >> ~/.bashrc && \
    echo "fi" >> ~/.bashrc && \
    echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "export PS1='\\W\$ '" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
    echo "" >> ~/.bashrc

USER ivpldock

RUN echo "" >> ~/.bashrc && \
    echo "# Set container type for banner" >> ~/.bashrc && \
    echo "export CONTAINER_TYPE='Workspace Container'" >> ~/.bashrc && \
    echo "# Load InvoicePlane Banner" >> ~/.bashrc && \
    echo "if [ -f ~/invoiceplane-banner.sh ]; then" >> ~/.bashrc && \
    echo "    source ~/invoiceplane-banner.sh" >> ~/.bashrc && \
    echo "fi" >> ~/.bashrc && \
    echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "export PS1='\\W\$ '" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
    echo "" >> ~/.bashrc

###########################################################################
# Composer:
###########################################################################

USER root

# Add the composer.json
COPY workspace/composer.json /home/ivpldock/.composer/composer.json

# Add the auth.json for magento 2 credentials
COPY workspace/auth.json /home/ivpldock/.composer/auth.json

# Make sure that ~/.composer belongs to ivpldock
RUN chown -R ivpldock:ivpldock /home/ivpldock/.composer

# Export composer vendor path
RUN echo "" >> ~/.bashrc && \
    echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc

# Update composer
ARG COMPOSER_VERSION=2
ENV COMPOSER_VERSION ${COMPOSER_VERSION}
RUN set -eux; \
  composer self-update --${COMPOSER_VERSION};

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

COPY workspace/crontab /etc/cron.d

RUN chmod -R 644 /etc/cron.d

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
    ###########################################################################
    # BZ2:
    ###########################################################################
    if [ ${INSTALL_BZ2} = true ]; then \
      (apt-get -yqq install php${IVPLDOCK_PHP_VERSION}-bz2 || \
       (apt-get -yqq install libbz2-dev && \
        (pecl install bz2 || true) && \
        mkdir -p /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d && \
        echo "extension=bz2.so" > /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/bz2.ini && \
        ln -sf /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/bz2.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-bz2.ini)); \
    fi; \
    ###########################################################################
    # GMP (GNU Multiple Precision):
    ###########################################################################
    if [ ${INSTALL_GMP} = true ]; then \
      # Install the PHP GMP extension
      (apt-get -yqq install php${IVPLDOCK_PHP_VERSION}-gmp || \
       (apt-get -yqq install libgmp-dev && \
        (pecl install gmp || true) && \
        mkdir -p /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d && \
        echo "extension=gmp.so" > /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/gmp.ini && \
        ln -sf /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/gmp.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-gmp.ini)); \
    fi; \
    ###########################################################################
    # GnuPG:
    ###########################################################################
    if [ ${INSTALL_GNUPG} = true ]; then \
        apt-get -yqq install php${IVPLDOCK_PHP_VERSION}-gnupg; \
    fi; \
    ###########################################################################
    # SSH2:
    ###########################################################################
    if [ ${INSTALL_SSH2} = true ]; then \
      # Install the PHP SSH2 extension
      apt-get -yqq install libssh2-1-dev php${IVPLDOCK_PHP_VERSION}-ssh2; \
    fi; \
    ###########################################################################
    # SOAP:
    ###########################################################################
    if [ ${INSTALL_SOAP} = true ]; then \
      # Install the PHP SOAP extension
      apt-get -yqq install libxml2-dev php${IVPLDOCK_PHP_VERSION}-soap; \
    fi; \
    ###########################################################################
    # XSL:
    ###########################################################################
    if [ ${INSTALL_XSL} = true ]; then \
      # Install the PHP XSL extension
      apt-get -yqq install libxslt-dev php${IVPLDOCK_PHP_VERSION}-xsl; \
    fi

###########################################################################

ARG INSTALL_LDAP=false
ARG INSTALL_SMB=false
ARG INSTALL_IMAP=false
ARG INSTALL_SUBVERSION=false

RUN set -eux; \
    ###########################################################################
    # IMAP:
    ###########################################################################
    if [ ${INSTALL_IMAP} = true ]; then \
        (apt-get install -yqq php${IVPLDOCK_PHP_VERSION}-imap || \
         (apt-get install -yqq libc-client-dev libkrb5-dev && \
          (pecl install imap || true) && \
          mkdir -p /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d && \
          echo "extension=imap.so" > /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/imap.ini && \
          ln -sf /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/imap.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-imap.ini)); \
    fi;

###########################################################################
# xDebug:
###########################################################################

USER root

RUN apt update -y

ARG INSTALL_XDEBUG=false
# Configure Xdebug with dynamic client_host from .env
ARG XDEBUG_CLIENT_HOST
ARG XDEBUG_PORT=9003

RUN (apt-get install -yqq pkg-config php-xml php${IVPLDOCK_PHP_VERSION}-xml || true) && \
  (pecl install xdebug-3.3.0 || true) && \
  (echo "zend_extension=xdebug.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-xdebug.ini || true) && \
  # Verify Xdebug installation
  if ! php -m | grep -q xdebug; then \
    echo "WARNING: Xdebug extension is not loaded after installation attempt"; \
  fi

RUN echo "##### PHP Version #####" \
    ${IVPLDOCK_PHP_VERSION} \
    "##### /PHP Version #####"

# ADD for REMOTE debugging
COPY workspace/xdebug.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini

# Configure Xdebug settings based on PHP version
# For Xdebug 3 (PHP 7.3, 7.4, 8.x): Use trigger mode to prevent connection warnings during build
# For Xdebug 2 (older PHP): Keep autostart disabled to prevent connection warnings during build
RUN if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ] || { [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ] && { [ $(php -r "echo PHP_MINOR_VERSION;") = "4" ] || [ $(php -r "echo PHP_MINOR_VERSION;") = "3" ] ;} ;}; then \
  sed -i "s/xdebug.remote_host=/xdebug.client_host=/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_connect_back=0/xdebug.discover_client_host=false/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug\.\(remote_port\|client_port\)=[0-9]*/xdebug.client_port=${XDEBUG_PORT}/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.profiler_enable=0/; xdebug.profiler_enable=0/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.profiler_output_dir=/xdebug.output_dir=/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_mode=req/; xdebug.remote_mode=req/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_autostart=0/xdebug.start_with_request=trigger/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_enable=0/xdebug.mode=debug/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini \
;else \
  sed -i "s/xdebug.remote_autostart=0/xdebug.remote_autostart=0/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_enable=0/xdebug.remote_enable=1/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini \
;fi
RUN sed -i "s/xdebug.cli_color=0/xdebug.cli_color=1/" /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/xdebug.ini

###########################################################################
# pcov:
###########################################################################

USER root

# Install pcov for code coverage
RUN pecl install pcov && \
    echo "extension=pcov.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-pcov.ini

#echo "pcov.enabled" >> /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-pcov.ini

###########################################################################
# PHPREDIS EXTENSION
###########################################################################

ARG INSTALL_PHPREDIS=false

RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    apt-get update \
    && (apt-get install -yqq php${IVPLDOCK_PHP_VERSION}-redis || \
        ((pecl install redis || true) && \
         mkdir -p /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d && \
         echo "extension=redis.so" > /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/redis.ini && \
         ln -sf /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/redis.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-redis.ini)) \
;fi

###########################################################################
# Libpng16 EXTENSION
###########################################################################

ARG INSTALL_LIBPNG=false

RUN if [ ${INSTALL_LIBPNG} = true ]; then \
    apt-get -yqq install libpng16-16 \
;fi

###########################################################################
# Inotify EXTENSION:
###########################################################################

ARG INSTALL_INOTIFY=false

RUN if [ ${INSTALL_INOTIFY} = true ]; then \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      pecl -q install inotify-0.1.6 && \
      echo "extension=inotify.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/inotify.ini && \
      ln -s /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/inotify.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-inotify.ini; \
    else \
      pecl -q install inotify && \
      echo "extension=inotify.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/inotify.ini && \
      ln -s /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/inotify.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-inotify.ini \
    ;fi \
;fi

###########################################################################
# fswatch
###########################################################################

ARG INSTALL_FSWATCH=false

RUN if [ ${INSTALL_FSWATCH} = true ]; then \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 47FE03C1 \
    && add-apt-repository -y ppa:hadret/fswatch \
    || apt-get update -yqq \
    && apt-get -y install fswatch \
;fi

USER ivpldock

###########################################################################
# Node / NVM:
###########################################################################

# Check if NVM needs to be installed
ARG NODE_VERSION=node
ENV NODE_VERSION ${NODE_VERSION}
ARG INSTALL_NODE=false
ARG INSTALL_NPM_GULP=false
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

RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install 16 \
    && nvm install 18 \
    && nvm install 20 \
    && nvm alias 20

# Wouldn't execute when added to the RUN statement in the above block
# Source NVM when loading bash since ~/.profile isn't loaded on non-login shell
RUN echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc

# Add NVM binaries to root's .bashrc
USER root

RUN echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="/home/ivpldock/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc

# Make it so the node modules can be executed with 'docker-compose exec'
# We'll create symbolic links into '/usr/local/bin'.
RUN find $NVM_DIR -type f -name node -exec ln -s {} /usr/local/bin/node \; && \
    NODE_MODS_DIR="$NVM_DIR/versions/node/$(node -v)/lib/node_modules" && \
    ln -s $NODE_MODS_DIR/gulp/bin/gulp.js /usr/local/bin/gulp && \
    ln -s $NODE_MODS_DIR/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s $NODE_MODS_DIR/npm/bin/npx-cli.js /usr/local/bin/npx

# Mount .npmrc into home folder
COPY workspace/.npmrc /root/.npmrc
COPY workspace/.npmrc /home/${IVPLDOCK_USER}/.npmrc

###########################################################################
# YARN:
###########################################################################

USER ${IVPLDOCK_USER}

ARG INSTALL_YARN=false
ARG YARN_VERSION=latest
ENV YARN_VERSION ${YARN_VERSION}

RUN [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && \
    curl -o- -L https://yarnpkg.com/install.sh | bash; \
    echo "" >> ~/.bashrc; \
    echo 'export PATH="$HOME/.yarn/bin:$PATH"' >> ~/.bashrc; \
    echo "" >> ~/.zshrc; \
    echo 'export PATH="$HOME/.yarn/bin:$PATH"' >> ~/.zshrc

# Add YARN binaries to root's .bashrc
USER root

RUN echo "" >> ~/.bashrc && \
    echo 'export YARN_DIR="/home/${IVPLDOCK_USER}/.yarn"' >> ~/.bashrc && \
    echo 'export PATH="$YARN_DIR/bin:$PATH"' >> ~/.bashrc

# Add PATH for YARN
ENV PATH $PATH:/home/${IVPLDOCK_USER}/.yarn/bin

USER root

###########################################################################
# Image optimizers:
###########################################################################

USER root

ARG INSTALL_IMAGE_OPTIMIZERS=false

RUN if [ ${INSTALL_IMAGE_OPTIMIZERS} = true ]; then \
    apt-get install -y jpegoptim optipng pngquant gifsicle && \
    if [ ${INSTALL_NODE} = true ]; then \
        exec bash && . ~/.bashrc && npm install -g svgo \
    ;fi\
;fi

USER ivpldock

###########################################################################
# PYTHON2:
###########################################################################
USER root

ARG INSTALL_PYTHON=false

###########################################################################
# PYTHON3:
###########################################################################

ARG INSTALL_PYTHON3=false

RUN if [ ${INSTALL_PYTHON3} = true ]; then \
  apt-get -y install python3 python3-dev build-essential  \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py  \
  && python3 get-pip.py  \
  && rm get-pip.py  \
  && python3 -m pip install --upgrade --force-reinstall pip  \
  && python3 -m pip install --upgrade virtualenv \
;fi

USER ivpldock

###########################################################################
# ImageMagick:
###########################################################################

USER root

ARG INSTALL_IMAGEMAGICK=false
ARG IMAGEMAGICK_VERSION=latest
ENV IMAGEMAGICK_VERSION ${IMAGEMAGICK_VERSION}

RUN if [ ${INSTALL_IMAGEMAGICK} = true ]; then \
    apt-get install -y libmagickwand-dev imagemagick && \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
      apt-get install -y git && \
      cd /tmp && \
      if [ ${IMAGEMAGICK_VERSION} = "latest" ]; then \
        git clone https://github.com/Imagick/imagick; \
      else \
        git clone --branch ${IMAGEMAGICK_VERSION} https://github.com/Imagick/imagick; \
      fi && \
      cd imagick && \
      phpize && \
      ./configure && \
      make && \
      make install && \
      rm -r /tmp/imagick; \
    else \
      (pecl install imagick || true); \
    fi && \
    echo "extension=imagick.so" >> /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/imagick.ini && \
    ln -s /etc/php/${IVPLDOCK_PHP_VERSION}/mods-available/imagick.ini /etc/php/${IVPLDOCK_PHP_VERSION}/cli/conf.d/20-imagick.ini && \
    php -m | grep -q 'imagick' \
;fi

###########################################################################
USER root

ARG INSTALL_MYSQL_CLIENT=false

RUN set -eux; \
  ###########################################################################
  # MySQL Client:
  ###########################################################################
  if [ ${INSTALL_MYSQL_CLIENT} = true ]; then \
    apt-get -yqq install mysql-client; \
  fi;


#####################################
# wkhtmltopdf:
#####################################

USER root

ARG INSTALL_WKHTMLTOPDF=false
ARG WKHTMLTOPDF_VERSION=0.12.6-1

RUN if [ ${INSTALL_WKHTMLTOPDF} = true ]; then \
   ARCH=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) \
   && apt-get install -y \
   libxrender1 \
   libfontconfig1 \
   libx11-dev \
   libjpeg62 \
   libxtst6 \
   fontconfig \
   libjpeg-turbo8-dev \
   xfonts-base \
   xfonts-75dpi \
   wget \
   && (wget "https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}.focal_${ARCH}.deb" \
   && dpkg -i "wkhtmltox_${WKHTMLTOPDF_VERSION}.focal_${ARCH}.deb" \
   && apt -f install) || echo "wkhtmltopdf installation failed, continuing..." \
;fi

###########################################################################
# Bash Git Prompt
###########################################################################

ARG INSTALL_GIT_PROMPT=false

COPY workspace/git-prompt.sh /tmp/git-prompt

RUN if [ ${INSTALL_GIT_PROMPT} = true ]; then \
    git clone https://github.com/magicmonty/bash-git-prompt.git /root/.bash-git-prompt --depth=1 && \
    cat /tmp/git-prompt >> /root/.bashrc && \
    rm /tmp/git-prompt \
;fi

###########################################################################
# Check PHP version:
###########################################################################

RUN set -xe; php -v | head -n 1 | grep -q "PHP ${IVPLDOCK_PHP_VERSION}."

###########################################################################
# Oh My ZSH!
###########################################################################

USER root

ARG SHELL_OH_MY_ZSH=false
RUN if [ ${SHELL_OH_MY_ZSH} = true ]; then \
    apt install -y zsh \
;fi

ARG SHELL_OH_MY_ZSH_AUTOSUGESTIONS=false
ARG SHELL_OH_MY_ZSH_ALIASES=false

USER ivpldock
RUN if [ ${SHELL_OH_MY_ZSH} = true ]; then \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --keep-zshrc" && \
    sed -i -r 's/^plugins=\(.*?\)$/plugins=(laravel composer)/' /home/ivpldock/.zshrc && \
    echo '\n\
bindkey "^[OB" down-line-or-search\n\
bindkey "^[OC" forward-char\n\
bindkey "^[OD" backward-char\n\
bindkey "^[OF" end-of-line\n\
bindkey "^[OH" beginning-of-line\n\
bindkey "^[[1~" beginning-of-line\n\
bindkey "^[[3~" delete-char\n\
bindkey "^[[4~" end-of-line\n\
bindkey "^[[5~" up-line-or-history\n\
bindkey "^[[6~" down-line-or-history\n\
bindkey "^?" backward-delete-char\n' >> /home/ivpldock/.zshrc && \
  if [ ${SHELL_OH_MY_ZSH_AUTOSUGESTIONS} = true ]; then \
    sh -c "git clone https://github.com/zsh-users/zsh-autosuggestions /home/ivpldock/.oh-my-zsh/custom/plugins/zsh-autosuggestions" && \
    sed -i 's~plugins=(~plugins=(zsh-autosuggestions ~g' /home/ivpldock/.zshrc && \
    sed -i '1iZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' /home/ivpldock/.zshrc && \
    sed -i '1iZSH_AUTOSUGGEST_STRATEGY=(history completion)' /home/ivpldock/.zshrc && \
    sed -i '1iZSH_AUTOSUGGEST_USE_ASYNC=1' /home/ivpldock/.zshrc && \
    sed -i '1iTERM=xterm-256color' /home/ivpldock/.zshrc \
  ;fi && \
  if [ ${SHELL_OH_MY_ZSH_ALIASES} = true ]; then \
    echo "" >> /home/ivpldock/.zshrc && \
    echo "# Load Custom Aliases" >> /home/ivpldock/.zshrc && \
    echo "source /home/ivpldock/aliases.sh" >> /home/ivpldock/.zshrc && \
    echo "" >> /home/ivpldock/.zshrc \
  ;fi \
;fi

USER root

###########################################################################
# ZSH User Aliases
###########################################################################

USER root

COPY workspace/aliases.sh /root/aliases.sh
COPY workspace/aliases.sh /home/ivpldock/aliases.sh

RUN if [ ${SHELL_OH_MY_ZSH} = true ]; then \
    sed -i 's/\r//' /root/aliases.sh && \
    sed -i 's/\r//' /home/ivpldock/aliases.sh && \
    chown ivpldock:ivpldock /home/ivpldock/aliases.sh && \
    echo "" >> ~/.zshrc && \
    echo "# Load Custom Aliases" >> ~/.zshrc && \
    echo "source ~/aliases.sh" >> ~/.zshrc && \
	  echo "" >> ~/.zshrc \
;fi

USER ivpldock

RUN if [ ${SHELL_OH_MY_ZSH} = true ]; then \
    echo "" >> ~/.zshrc && \
    echo "# Load Custom Aliases" >> ~/.zshrc && \
    echo "source ~/aliases.sh" >> ~/.zshrc && \
	  echo "" >> ~/.zshrc \
;fi

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

# Set default work directory
WORKDIR /var/www/projects
