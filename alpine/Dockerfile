FROM tiredofit/nginx-php-fpm:edge
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ARG GPERFTOOLS_VERSION=2.8
ARG VMIME_VERSION=v0.9.2k4

ENV KOPANO_CORE_VERSION=10.0.5 \
    KOPANO_WEBAPP_VERSION=4.2.0 \

    Z_PUSH_VERSION=2.5.2 \
    NGINX_LOG_ACCESS_LOCATION=/logs/nginx \
    NGINX_LOG_ERROR_LOCATION=/logs/nginx \
    NGINX_WEBROOT=/usr/share/kopano-webapp \
    PHP_ENABLE_GETTEXT=TRUE \
    PHP_ENABLE_SIMPLEXML=TRUE \
    PHP_ENABLE_SOAP=TRUE \
    PHP_ENABLE_XMLWRITER=TRUE \
    PHP_ENABLE_TOKENIZER=TRUE \
    PHP_LOG_LOCATION=/logs/php-fpm

RUN set -x && \
    apk update && \
    apk upgrade && \
    apk add -t .kopanocore-build-deps \
                autoconf \
                automake \
                build-base \
                cmake \
                coreutils \
                db-dev \
                gettext \
                git \
                gnu-libiconv \
                gsoap-dev \
                jsoncpp-dev \
                krb5-dev \
                libical-dev \
                libidn2-dev \
                libpthread-stubs \
                libtool \
                libxml2-dev \
                linux-pam-dev \
                mariadb-connector-c-dev \
                ncurses5 \
                ncurses5-libs \
                openldap-dev \
                openssl-dev \
                php7-dev \
                python2-dev \
                rrdtool-dev \
                swig \
                tidyhtml-dev \
                util-linux \
                xapian-core-dev \
                zlib-dev \
##Gperftools??
##needs kcoidc
                && \
    \
#    git clone -b kopanocore-${KOPANO_CORE_VERSION} https://github.com/Kopano-dev/kopano-core /usr/src/core
    git clone https://github.com/Kopano-dev/kopano-core /usr/src/core

    ### Gperftools
RUN git clone -b gperftools-${GPERFTOOLS_VERSION} https://github.com/gperftools/gperftools /usr/src/gperftools && \
    cd /usr/src/gperftools && \
    libtoolize --force && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make && \
    make install

    ### LibHX
RUN git clone git://git.inai.de/libhx /usr/src/libhx && \
    cd /usr/src/libhx && \
    libtoolize --force && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make && \
    make install

    ### Vmime
RUN git clone -b ${VMIME_VERSION} https://github.com/Kopano-dev/vmime /usr/src/vmime && \
    apk add -t .vmime-buld-deps \
                cmake \
                doxygen \
                libgsasl-dev \
                gnutls-dev \
                && \
    cd /usr/src/vmime && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -G "Unix Makefiles" && \
    make && \
    make install

    ### LibS3
RUN git clone https://github.com/bji/libs3 /usr/src/libs3 && \
    apk add -t .libs3-build-deps \
                coreutils \
                curl-dev \
                zlib-dev \
                && \
    cd /usr/src/libs3 && \
    make && \
    DESTDIR=/usr make install

    ### Kopano Core
RUN cd /usr/src/core && \
    libtoolize --force && \
     autoreconf -fiv && \
    ./configure --enable-epoll \
            --enable-unicode \
            --enable-python \
            --disable-static \
            --with-userscript-prefix=/etc/kopano/userscripts \
            --with-quotatemplate-prefix=/etc/kopano/quotamail


