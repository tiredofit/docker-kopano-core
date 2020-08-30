FROM tiredofit/nginx-php-fpm:edge as core-builder
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ARG GPERFTOOLS_VERSION=2.8
ARG VMIME_VERSION=v0.9.2k4
ENV KOPANO_CORE_VERSION=kopanocore-10.0.6 \
    KOPANO_WEBAPP_VERSION=4.2.0 \
    Z_PUSH_VERSION=2.5.2

RUN set -x && \
    apk update && \
    apk upgrade && \
    apk add -t .kopanocore-build-deps \
                autoconf \
                automake \
                binutils \
                build-base \
                cmake \
                coreutils \
                db-dev \
                gettext-dev \
                git \
                gnu-libiconv \
                gsoap-dev \
                jsoncpp-dev \
                krb5-dev \
                libical-dev \
                libidn2-dev \
                libpthread-stubs \
                libtool \
                libuuid \
                libxml2-dev \
                linux-pam-dev \
                mariadb-connector-c-dev \
                #musl-libintl \
    #                ncurses5 \
#                ncurses5-libs \
                ncurses-dev \
                openldap-dev \
                openssl-dev \
                php7-dev \
                python3-dev \
                py3-dateutil \
                py3-flake8 \
                py3-pillow \
                py3-pytest \
                py3-setuptools \
                py3-tz \
                py3-tzlocal \
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
    git clone https://github.com/Kopano-dev/kopano-core /usr/src/kopano-core && \
    cd /usr/src/kopano-core && \
    git checkout ${KOPANO_CORE_VERSION}

    ### Gperftools
RUN git clone -b gperftools-${GPERFTOOLS_VERSION} https://github.com/gperftools/gperftools /usr/src/gperftools && \
    cd /usr/src/gperftools && \
    libtoolize --force && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install

    ### LibHX
RUN git clone git://git.inai.de/libhx /usr/src/libhx && \
    cd /usr/src/libhx && \
    libtoolize --force && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
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
    make -j$(nproc) && \
    make install

    ### LibS3
RUN git clone https://github.com/bji/libs3 /usr/src/libs3 && \
    apk add -t .libs3-build-deps \
                coreutils \
                curl-dev \
                zlib-dev \
                && \
    cd /usr/src/libs3 && \
    make -j$(nproc) && \
    make DESTDIR=/usr install

    ### Kopano Core
RUN cd /usr/src/kopano-core && \
    libtoolize --force && \
     autoreconf -fiv && \
    ./configure \
                --prefix / \
                --exec-prefix=/usr \
                --localstatedir=/var \
                --libdir=/usr/lib \
                --sysconfdir=/etc \
                --sbindir=/usr/bin \
                --datarootdir=/usr/share \
                --includedir=/usr/include \
                --enable-epoll \
                --enable-release \
                --enable-pybind \
                #--enable-kcoidc \
                PYTHON="$(which python3)" \
                PYTHON_CFLAGS="$(pkg-config python3 --cflags)"\
                PYTHON_LIBS="$(pkg-config python3 --libs)" \
                TCMALLOC_CFLAGS=" " \
                TCMALLOC_LIBS="-ltcmalloc_minimal"

RUN cd /usr/src/kopano-core && \
    make -j$(nproc)
