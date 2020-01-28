FROM php:7.3-fpm-alpine

LABEL maintainer="https://www.velvetropes.com"
LABEL application=velvetropes


# php modules
ENV PHALCON_VERSION=3.4.4
RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        libxml2-dev \
#        zlib-dev \
        libzip-dev \
    && docker-php-ext-configure zip --with-libzip=/usr/include \
    && docker-php-ext-install zip \
    && pecl install redis xdebug \
    && docker-php-ext-enable redis xdebug \
    && docker-php-ext-install opcache pdo_mysql mysqli soap zip \
# cphalcon
    && curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz \
    && tar xzf v${PHALCON_VERSION}.tar.gz \
    && docker-php-ext-install ${PWD}/cphalcon-${PHALCON_VERSION}/build/php7/64bits \
    && rm -rf v${PHALCON_VERSION}.tar.gz cphalcon-${PHALCON_VERSION} \
    && apk del .build-deps

# packages
RUN apk add --no-cache \
    git \
    nginx \
    nginx-mod-http-image-filter \
    nginx-mod-stream-geoip \
    # php graphic drawing library
    php7-gd \
    # loading shared library libzip.so
    php7-zip \
    # PHP7 extension: BC Math
    musl \
    php7-common \
    php7-bcmath \
    #can be removed
    openrc --no-cache \
    runit \
    unzip

# Use the docker-php-ext-install script to add gd
#RUN apk add --no-cache libpng libpng-dev && docker-php-ext-install gd && apk del libpng-dev
# https://github.com/docker-library/php/issues/225
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev && \
  docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
  docker-php-ext-configure bcmath --enable-bcmath && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} \
   gd \
   bcmath && \
  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev


# devtools
ENV DEVTOOLS_VERSION=3.4.3
RUN curl -LO https://github.com/phalcon/phalcon-devtools/archive/v${DEVTOOLS_VERSION}.tar.gz \
    && tar xzf v${DEVTOOLS_VERSION}.tar.gz \
    && mv phalcon-devtools-${DEVTOOLS_VERSION} /usr/local/phalcon-devtools \
    && ln -s /usr/local/phalcon-devtools/phalcon.php /usr/local/bin/phalcon \
    && rm -f v${DEVTOOLS_VERSION}.tar.gz

# composer
ENV COMPOSER_VERSION=1.9.0
RUN curl -L https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --version=${COMPOSER_VERSION} --install-dir=/usr/local/bin --filename=composer \
    && rm -f composer-setup.php

WORKDIR /app

# NGINX config
RUN mkdir -p /var/spool/nginx/client_temp
COPY conf/ /etc/
#COPY conf/runit /etc/runit

# Configuration File (php.ini) Path	/usr/local/etc/php
COPY php/ /usr/local/etc/php/

# COMPOSER copy
COPY conf/composer  /app/

RUN ./run-composer.sh

# change www-data user id
RUN sed -ri 's/^www-data:x:82:82:/www-data:x:1000:1000:/' /etc/passwd
