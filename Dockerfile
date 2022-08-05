FROM php:8.1.8-fpm-alpine3.16 AS foundation

LABEL Maintainer="Carsten Jonstrup" \
      Description="latest PHP8 fpm Docker image with pdflib" \
      License="MIT License" \
      Version="8.1.8"

# Environments
ENV TZ=Europe/Copenhagen
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/usr/local/share/composer

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync && apk add --no-cache --update libc6-compat supervisor && \
    install-php-extensions \
        apcu \
        bcmath \
        mcrypt \
        pdo_pgsql \
        #protobuf \
        pgsql \
        #grpc \
        #geospatial \
        gd \
        zip \
    && \
    install-php-extensions @composer && \
    : && \
    rm -rf /tmp/* /var/cache/apk/*

RUN set -ex && \
    PHP_INI_DIR=$(php --ini | grep "Scan for additional .ini files in" | cut -d':' -f2 | cut -d' ' -f2 | head -n1) && \
    ## php runtime environments
    # { \
    # echo "memory_limit = ${PHP_MEMORY_LIMIT}"; \
    # echo "upload_max_filesize = ${MAX_UPLOAD}"; \
    # echo "max_file_uploads = ${PHP_MAX_FILE_UPLOAD}"; \
    # echo "post_max_size = ${PHP_MAX_POST}"; \
    # echo "cgi.fix_pathinfo= 0"; \
    # } > $PHP_INI_DIR/zz-php-env.ini && \
    : && \
    ## timezone
    echo "date.timezone = ${TZ}" > $PHP_INI_DIR/zz-timezone.ini && \
    : && \
    ## remove PHP version from the X-Powered-By HTTP header
    ## test: curl -I -H "Accept-Encoding: gzip, deflate" https://www.yourdomain.com
    echo 'expose_php = off' > $PHP_INI_DIR/zz-hide-header-version.ini

FROM foundation AS pdflib
RUN set -ex && \
    ## PDFlib
    ## https://www.pdflib.com/download/pdflib-product-family/ \
    UNAME_M=$(uname -m) && \
    curl -fSL -o pdflib.tar.gz https://www.pdflib.com/binaries/PDFlib/1000/PDFlib-10.0.0p1-Linux-${UNAME_M}-php.tar.gz && \
    tar -xzf pdflib.tar.gz && \
    mv PDFlib-* pdflib && \
    PHP_EXT_DIR=$(php-config --extension-dir) && \
    PHP_MAIN_VERSION=$(php --version | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1 | cut -d. -f1-2 | sed 's/\.//g') && \
    cp pdflib/bind/php/php-${PHP_MAIN_VERSION}0-nts/php_pdflib.so $PHP_EXT_DIR && \
    docker-php-ext-enable php_pdflib && \
    rm pdflib.tar.gz && \
    rm -r pdflib

FROM caddy:2.5.2-builder AS caddy-builder

RUN xcaddy build --output /caddy

FROM pdflib AS web

RUN mkdir /project && \
    mkdir /project/public

# Install caddy
COPY --from=caddy-builder /caddy /usr/local/bin/caddy

# Copy needed files and configuration
COPY php-fpm.conf /usr/local/etc/php-fpm.conf
COPY entrypoint.sh /entrypoint.sh
COPY wait-for-it.sh /usr/bin/wait-for-it
COPY Caddyfile /Caddyfile
COPY index.php /project/public/index.php
COPY supervisord.ini /supervisord.ini

WORKDIR /project

ENTRYPOINT ["/entrypoint.sh"]