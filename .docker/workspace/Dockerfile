#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#
# To edit the 'workspace' base Image, visit its repository on Github
#    https://github.com/ivpldock/workspace
#
# To change its version, see the available Tags on the Docker Hub:
#    https://hub.docker.com/r/ivpldock/workspace/tags/
#
# Note: Base Image name format {image-tag}-{php-version}
#

ARG IVPLDOCK_PHP_VERSION
ARG BASE_IMAGE_TAG_PREFIX=latest
FROM laradock/workspace:${BASE_IMAGE_TAG_PREFIX}-8.2

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

# Start as root
USER root

# Set up default environment variables, sourcing from .env where possible
ARG LARADOCK_USER
ARG WORKSPACE_WORKDIR
ARG TIMEZONE
ARG NODE_VERSION
ARG XDEBUG_PORT
ARG WORKSPACE_VITE_PORT

###########################################################################
# ivpldock non-root user:
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
    groupadd -g ${PGID} ${IVPLDOCK_USER} && \
    useradd -u ${PGID} -g ${IVPLDOCK_USER} -m ${IVPLDOCK_USER} && \
    usermod -p "*" ${IVPLDOCK_USER} -s /bin/bash

RUN apt-get update -yqq && \
    apt-get install -yqq apt-utils libzip-dev zip unzip nano \
    php8.2-imap php8.2-gmp \
    php8.2-redis \
    php8.2-zip \
    libpng-dev libjpeg-dev \
    libpng16-16 \
    libmagickwand-dev imagemagick jpegoptim optipng pngquant gifsicle && \
    pecl channel-update pecl.php.net

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

# Copy aliases and setup user environment
COPY ./aliases.sh /root/aliases.sh
COPY ./aliases.sh /home/${IVPLDOCK_USER}/aliases.sh

RUN sed -i 's/\r//' /root/aliases.sh && \
    sed -i 's/\r//' /home/${IVPLDOCK_USER}/aliases.sh && \
    chown ${IVPLDOCK_USER}:${IVPLDOCK_USER} /home/${IVPLDOCK_USER}/aliases.sh && \
    echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
    echo "export PS1='\W\$ '" >> ~/.bashrc && \
    echo "" >> ~/.bashrc && \
###########################################################################
# ZSH User Aliases
###########################################################################
    echo "" >> ~/.zshrc && \
    echo "# Load Custom Aliases" >> ~/.zshrc && \
    echo "source ~/aliases.sh" >> ~/.zshrc && \
    echo "" >> ~/.zshrc

USER ${IVPLDOCK_USER}

###########################################################################
# xDebug:
###########################################################################

USER root

# Configure Xdebug with dynamic client_host from .env
ARG XDEBUG_CLIENT_HOST
ARG XDEBUG_PORT=9003

# ADD for REMOTE debugging
COPY ./xdebug.ini /etc/php/8.2/cli/conf.d/xdebug.ini
# Install the xdebug extension
# https://xdebug.org/docs/compat
  RUN apt-get install -yqq pkg-config php-xml php8.2-xml && \
  pecl install xdebug-3.3.0; \
  sed -i "s/xdebug.remote_host=/xdebug.client_host=/" /etc/php/8.2/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_connect_back=0/xdebug.discover_client_host=false/" /etc/php/8.2/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_port=9003/xdebug.client_port=${XDEBUG_PORT}/" /etc/php/8.2/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.profiler_enable=0/; xdebug.profiler_enable=0/" /etc/php/8.2/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.profiler_output_dir=/xdebug.output_dir=/" /etc/php/8.2/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_mode=req/; xdebug.remote_mode=req/" /etc/php/8.2/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_autostart=0/xdebug.start_with_request=yes/" /etc/php/8.2/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_enable=0/xdebug.mode=debug/" /etc/php/8.2/cli/conf.d/xdebug.ini && \
  sed -i "s/xdebug.cli_color=0/xdebug.cli_color=1/" /etc/php/8.2/cli/conf.d/xdebug.ini && \
  echo "zend_extension=xdebug.so" > /etc/php/8.2/cli/conf.d/20-xdebug.ini && \
  echo "xdebug.client_host=${XDEBUG_CLIENT_HOST:-172.17.0.1}" >> /etc/php/8.2/cli/conf.d/20-xdebug.ini && \
  echo "xdebug.client_port=${XDEBUG_PORT}" >> /etc/php/8.2/cli/conf.d/20-xdebug.ini && \
  echo "xdebug.mode=debug" >> /etc/php/8.2/cli/conf.d/20-xdebug.ini


USER root

###########################################################################
# PYTHON2:
###########################################################################
RUN apt-get -y install python python-dev build-essential  \
  && curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py  \
  && python get-pip.py  \
  && rm get-pip.py  \
  && python -m pip install --upgrade pip  \
  && python -m pip install --upgrade virtualenv

###########################################################################
# PYTHON3:
###########################################################################
RUN apt-get -y install python3 python3-dev build-essential  \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py  \
  && python3 get-pip.py  \
  && rm get-pip.py  \
  && python3 -m pip install --upgrade --force-reinstall pip  \
  && python3 -m pip install --upgrade virtualenv



###########################################################################
# ImageMagick:
###########################################################################

USER root

ARG INSTALL_IMAGEMAGICK=false
ARG IMAGEMAGICK_VERSION=latest
ENV IMAGEMAGICK_VERSION ${IMAGEMAGICK_VERSION}

RUN apt-get install -y libmagickwand-dev imagemagick && \
      apt-get install -y git && \
      cd /tmp && \
      git clone https://github.com/Imagick/imagick; \
      cd imagick && \
      phpize && \
      ./configure && \
      make && \
      make install && \
      rm -r /tmp/imagick; \
    echo "extension=imagick.so" >> /etc/php/8.2/mods-available/imagick.ini && \
    ln -s /etc/php/8.2/mods-available/imagick.ini /etc/php/8.2/cli/conf.d/20-imagick.ini && \
    php -m | grep -q 'imagick'

###########################################################################
# Node / NVM:
###########################################################################

ENV NVM_DIR /home/${IVPLDOCK_USER}/.nvm

RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install 16 \
    && nvm install 18 \
    && nvm install 20 \
    && nvm alias 20 \
    ln -s /home/${IVPLDOCK_USER}/.nvm/versions/node/v${NODE_VERSION}/bin/node /usr/local/bin/node && \
    ln -s /home/${IVPLDOCK_USER}/.nvm/versions/node/v${NODE_VERSION}/bin/npm /usr/local/bin/npm

# Wouldn't execute when added to the RUN statement in the above block
# Source NVM when loading bash since ~/.profile isn't loaded on non-login shell
###########################################################################
# USER ivpldock:
###########################################################################
RUN if [ ${INSTALL_NODE} = true ]; then \
    echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="$NVM_DIR/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc \
;fi

# Add NVM binaries to root's .bashrc
USER root

RUN echo "" >> ~/.bashrc && \
    echo 'export NVM_DIR="/home/${IVPLDOCK_USER}/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc

# Make it so the node modules can be executed with 'docker-compose exec'
# We'll create symbolic links into '/usr/local/bin'.
RUN if [ ${INSTALL_NODE} = true ]; then \
    find $NVM_DIR -type f -name node -exec ln -s {} /usr/local/bin/node \; && \
    NODE_MODS_DIR="$NVM_DIR/versions/node/$(node -v)/lib/node_modules" && \
    ln -s $NODE_MODS_DIR/gulp/bin/gulp.js /usr/local/bin/gulp && \
    ln -s $NODE_MODS_DIR/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s $NODE_MODS_DIR/npm/bin/npx-cli.js /usr/local/bin/npx \
;fi

# Mount .npmrc into home folder
COPY ./.npmrc /root/.npmrc
COPY ./.npmrc /home/${IVPLDOCK_USER}/.npmrc

###########################################################################
# YARN:
###########################################################################

USER ${IVPLDOCK_USER}

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

###########################################################################
# Composer:
###########################################################################
# Install Composer (non-global)
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Install pcov for code coverage
RUN pecl install pcov && \
    echo "extension=pcov.so" >> /etc/php/8.2/cli/conf.d/20-pcov.ini

###########################################################################
# Check PHP version:
###########################################################################

RUN set -xe; php -v | head -n 1 | grep -q "PHP 8.2."

###########################################################################
# Oh My ZSH!
###########################################################################

USER root
# Configure Oh My Zsh with custom prompt (working directory only + git branch)
RUN apt install -y zsh && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --keep-zshrc" && \
    sed -i -r 's/^plugins=\(.*?\)$/plugins=(laravel composer)/' /home/${IVPLDOCK_USER}/.zshrc && \
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
    bindkey "^?" backward-delete-char\n' >> /home/${IVPLDOCK_USER}/.zshrc && \
    sh -c "git clone https://github.com/zsh-users/zsh-autosuggestions /home/${IVPLDOCK_USER}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" && \
    sed -i 's~plugins=(~plugins=(zsh-autosuggestions ~g' /home/${IVPLDOCK_USER}/.zshrc && \
    sed -i '1iZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' /home/${IVPLDOCK_USER}/.zshrc && \
    sed -i '1iZSH_AUTOSUGGEST_STRATEGY=(history completion)' /home/${IVPLDOCK_USER}/.zshrc && \
    sed -i '1iZSH_AUTOSUGGEST_USE_ASYNC=1' /home/${IVPLDOCK_USER}/.zshrc && \
    sed -i '1iTERM=xterm-256color' /home/${IVPLDOCK_USER}/.zshrc && \
    echo "" >> /home/${IVPLDOCK_USER}/.zshrc && \
    echo "# Load Custom Aliases" >> /home/${IVPLDOCK_USER}/.zshrc && \
    echo "source /home/${IVPLDOCK_USER}/aliases.sh" >> /home/${IVPLDOCK_USER}/.zshrc && \
    echo "" >> /home/${IVPLDOCK_USER}/.zshrc \
    echo "PROMPT='%B%F{blue}%1~%f %F{cyan}$(git_prompt_info)%f%B '" >> /home/${IVPLDOCK_USER}/.zshrc

#
#--------------------------------------------------------------------------
# Final Touches
#--------------------------------------------------------------------------
#
USER root

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -f /var/log/lastlog /var/log/faillog

RUN chown -R ${IVPLDOCK_USER}:${IVPLDOCK_USER} /home/${IVPLDOCK_USER}

# Open additional ports for Vite and Xdebug
EXPOSE ${XDEBUG_PORT} ${VITE_PORT}

# Set default work directory
WORKDIR ${WORKDIR}
