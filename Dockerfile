ARG IMG_DB_VERSION=22.04
FROM ubuntu:${IMG_DB_VERSION}

LABEL MAINTAINER="https://github.com/nowstton"

## ARGs
ARG USERID=0
ARG USERNAME=root
ARG WORK_DIR=/var/www
ARG NODE_LTS_VERSION=18
ARG DEBIAN_FRONTEND=noninteractive
ARG COMPOSER_MEMORY_LIMIT=-1
ARG COMPOSER_PROCESS_TIMEOUT=5000
# ARG COMPOSER_ALLOW_SUPERUSER=1
ARG NGINX_PHP_USER=www-data
ARG PHP_VERSION='8.2'
ARG PHP_SERVICE_NAME="php$PHP_VERSION-fpm"

## Set ENV variables
## TZ can be America/Sao_Paulo or UTC
ENV TZ UTC
ENV COMPOSER_MEMORY_LIMIT ${COMPOSER_MEMORY_LIMIT}
ENV COMPOSER_PROCESS_TIMEOUT ${COMPOSER_PROCESS_TIMEOUT}
# ENV COMPOSER_ALLOW_SUPERUSER ${COMPOSER_ALLOW_SUPERUSER}
ENV NGINX_PHP_USER ${NGINX_PHP_USER}
ENV PHP_VERSION ${PHP_VERSION}
ENV PHP_SERVICE_NAME ${PHP_SERVICE_NAME}
ENV USERID ${USERID}
ENV USERNAME ${USERNAME}

## Set Timezone to UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

## Update package list and install main sytem utils
RUN apt-get update && apt-get install -f -y --no-install-recommends gnupg gosu nano curl wget gnupg2 ca-certificates lsb-release \
  apt-transport-https software-properties-common \
  zip unzip gzip git sqlite3 libpng-dev python2

## Install Nginx
RUN curl -fsSL https://nginx.org/keys/nginx_signing.key  | gpg --dearmor -o /usr/share/keyrings/nginx-keyring.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://nginx.org/packages/$(lsb_release -is | sed -e 's/\(.*\)/\L\1/') $(lsb_release -cs) nginx" \
  | tee /etc/apt/sources.list.d/nginx.list \
  && apt-get update && apt-get install -f -y --no-install-recommends nginx

## Install Node JS and YARN
RUN curl -sL "https://deb.nodesource.com/setup_${NODE_LTS_VERSION}.x" | bash - \
  && apt-get update && apt-get install -f -y --no-install-recommends nodejs \
  && npm install -g npm@latest \
  && npm install --global yarn

# Install PHP
RUN add-apt-repository ppa:ondrej/php \
  && apt-get update && apt-get install -f -y --no-install-recommends \
  php${PHP_VERSION} php${PHP_VERSION}-cli php${PHP_VERSION}-fpm \
  php${PHP_VERSION}-pgsql php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-gd php${PHP_VERSION}-mongodb \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-opcache \
  php${PHP_VERSION}-mcrypt php${PHP_VERSION}-uuid \
  php${PHP_VERSION}-imap php${PHP_VERSION}-mysql php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-bz2 php${PHP_VERSION}-bcmath php${PHP_VERSION}-soap \
  php${PHP_VERSION}-intl php${PHP_VERSION}-readline \
  php${PHP_VERSION}-ldap \
  php${PHP_VERSION}-msgpack php${PHP_VERSION}-igbinary php${PHP_VERSION}-redis \
  php${PHP_VERSION}-memcached php${PHP_VERSION}-pcov \
  php-pear

## Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

## Clear APT cache
RUN apt-get -f -y --no-install-recommends autoremove \
  && apt-get clean \
  && rm -Rrf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Loading PHP ini
COPY .docker/services/webservice/php/fpm/pool.d/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
COPY .docker/services/webservice/php/php.ini /etc/php/${PHP_VERSION}/cli/php.ini
COPY .docker/services/webservice/php/php.ini /etc/php/${PHP_VERSION}/fpm/php.ini

## Nginx config files
COPY .docker/services/webservice/nginx/nginx.conf /etc/nginx/nginx.conf
COPY .docker/services/webservice/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

## Set working directory, this is where it all happens.
RUN rm -rf ${WORK_DIR}/html
WORKDIR ${WORK_DIR}

# Additional scripts
COPY .docker/scripts/docker-entry-point.sh /usr/local/bin/docker-entry-point
RUN chmod +x /usr/local/bin/docker-entry-point
COPY .docker/scripts/reload-permissions.sh /usr/bin/reload-permissions
COPY .docker/scripts/before-start.sh /usr/bin/before-start

RUN chmod +x /usr/bin/reload-permissions \
  && chmod +x /usr/bin/before-start

EXPOSE 80

ENTRYPOINT ["docker-entry-point"]
