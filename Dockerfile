FROM tiredofit/nginx-php-fpm:7.4
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ARG KOPANO_CORE_VERSION
ARG KOPANO_CORE_REPO_URL
ARG KOPANO_DEPENDENCY_HASH
ARG KOPANO_KCOIDC_REPO_URL
ARG KOPANO_KCOIDC_VERSION
ARG KOPANO_KDAV_VERSION
ARG KOPANO_WEBAPP_VERSION
ARG KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION
ARG KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION
ARG KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION
ARG KOPANO_WEBAPP_PLUGIN_FILES_VERSION
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_JODIT_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_JODIT_VERSION
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION
ARG KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION
ARG KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION
ARG KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_MDM_VERSION
ARG KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION
ARG KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL
ARG KOPANO_WEBAPP_PLUGIN_SMIME_VERSION
ARG KOPANO_WEBAPP_REPO_URL
ARG LIBS3_REPO_URL
ARG LIBS3_VERSION
ARG VMIME_REPO_URL
ARG VMIME_VERSION
ARG Z_PUSH_VERSION

ENV KOPANO_CORE_VERSION=${KOPANO_CORE_VERSION:-"kopanocore-10.0.6"} \
    KOPANO_KCOIDC_VERSION=${KOPANO_KCOIDC_VERSION:-"v0.9.2"} \
    KOPANO_KDAV_VERSION=${KOPANO_KDAV_VERSION:-"master"} \
    KOPANO_WEBAPP_VERSION=${KOPANO_WEBAPP_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_VERSION:-"tags/1.0.0"} \
    KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION=${KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION:-"tags/v1.0.1"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION:-"tags/v4.0.0"} \
    KOPANO_WEBAPP_PLUGIN_JODIT_VERSION=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_JODIT_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION=${KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION:-"tags/v1.0.1"} \
    KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION=${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION:-"1.0.2-1"} \
    KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION:-"tags/v4.0.0"} \
    KOPANO_WEBAPP_PLUGIN_SMIME_VERSION=${KOPANO_WEBAPP_PLUGIN_SMIME_VERSION:-"tags/v2.2.2"} \
    KOPANO_WEBAPP_PLUGIN_FILES_VERSION=${KOPANO_WEBAPP_PLUGIN_FILES_VERSION:-"tags/v4.0.0"} \
    KOPANO_WEBAPP_PLUGIN_MDM_VERSION=${KOPANO_WEBAPP_PLUGIN_MDM_VERSION:-"tags/v3.2"} \
    VMIME_VERSION=${VMIME_VERSION:-"v0.9.2k4"} \
    Z_PUSH_VERSION=${Z_PUSH_VERSION:-"2.6.1"} \
    \
    KOPANO_CORE_REPO_URL=${KOPANO_CORE_REPO_URL:-"https://github.com/Kopano-dev/kopano-core.git"} \
    KOPANO_KCOIDC_REPO_URL=${KOPANO_KCOIDC_REPO_URL:-"https://github.com/Kopano-dev/libkcoidc.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL:-"https://stash.kopano.io/scm/kwa/files-owncloud-backend.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL:-"https://stash.kopano.io/scm/kwa/files.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL:-"https://github.com/datamate-rethink-it/kopano-seafile-backend.git"} \
    KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL=${KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL:-"https://stash.kopano.io/scm/kwa/files-smb-backend.git"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL:-"https://stash.kopano.io/scm/kwa/htmleditor-minimaltiny.git"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL:-"https://stash.kopano.io/scm/kwa/htmleditor-quill.git"} \
    KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_VERSION:-"master"} \
    KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL=${KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL:-"https://stash.kopano.io/scm/kwa/intranet.git"} \
    KOPANO_WEBAPP_PLUGIN_JODIT_REPO_URL=${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_JODIT_REPO_URL:-"https://stash.kopano.io/scm/kwa/htmleditor-jodit.git"} \
    KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL=${KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL:-"https://stash.kopano.io/scm/kwa/mattermost.git"} \
    KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL=${KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL:-"https://stash.kopano.io/scm/kwa/mobile-device-management.git"} \
    KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL=${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL:-"https://cloud.siedl.net/nextcloud/index.php/s/3yKYARgGwfSZe2c/download"} \
    KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL=${KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL:-"https://stash.kopano.io/scm/kwa/smime.git"} \
    KOPANO_WEBAPP_REPO_URL=${KOPANO_WEBAPP_REPO_URL:-"https://stash.kopano.io/scm/kw/kopano-webapp.git"} \
    LIBS3_REPO_URL=${LIBS3_REPO_URL:-"https://github.com/bji/libs3"} \
    LIBS3_VERSION=${LIBS3_VERSION:-"master"} \
    NGINX_LOG_ACCESS_LOCATION=/logs/nginx \
    NGINX_LOG_ERROR_LOCATION=/logs/nginx \
    NGINX_WEBROOT=/usr/share/kopano-webapp \
    PHP_ENABLE_CREATE_SAMPLE_PHP=FALSE \
    PHP_ENABLE_GETTEXT=TRUE \
    PHP_ENABLE_PDO=TRUE \
    PHP_ENABLE_PDO_SQLITE=TRUE \
    PHP_ENABLE_SIMPLEXML=TRUE \
    PHP_ENABLE_SOAP=TRUE \
    PHP_ENABLE_TOKENIZER=TRUE \
    PHP_ENABLE_XMLWRITER=TRUE \
    PHP_LOG_LOCATION=/logs/php-fpm \
    VMIME_REPO_URL=${VMIME_REPO_URL:-"https://github.com/Kopano-dev/vmime/"}

ADD build-assets /build-assets

RUN set -x && \
    ### Add user and Group
    addgroup -g 998 kopano && \
    adduser -S -D -H -h /dev/null -s /sbin/nologin -G kopano -u 998 kopano && \
    \
    ### Upgrade Packages
    apk update && \
    apk upgrade && \
    \
    ### Install Dependencies
    mkdir -p .tiredofit && \
    apk add -t .build-deps \
               ### General
                autoconf \
                automake \
                build-base \
                go \
                git \
                pkgconf \
                py3-pip \
                python3-dev \
               ### Kopano Core
                curl-dev \
                db-dev \
                docbook-xsl \
                e2fsprogs \
                gnu-libiconv-dev \
                gsoap-dev \
                icu-dev \
                jsoncpp-dev \
                libev-dev \
                libffi-dev \
                libhx-dev \
                libical-dev \
                libtool \
                libxml2-dev \
                mariadb-dev \
                openldap-dev \
                php7-dev \
                py3-setuptools \
                python3-dev \
                swig \
                xapian-core-dev \
                xmlto \
                xorgproto \
               ### Kopano Webapp \
                apache-ant \
                gettext-dev \
                libxml2-dev \
                libxml2-utils \
                nodejs \
                nodejs-npm \
                openjdk8 \
                openssl-dev \
                ruby-dev \
                rsync \
                tidyhtml-dev \
                ## LibS3
                curl-dev \
                zlib-dev \
               ### VMime
                cmake \
                gnutls-dev \
                gtk+3.0-dev \
                libgsasl-dev \
               ### py-bsddb3
                db-dev \
                py3-setuptools \
                && \
    \
    apk add -t .run-deps \
                bash-completion \
                bison \
                boost \
                boost-libs \
                catdoc \
                coreutils \
                db \
                db-c++ \
                gnu-libiconv \
                gsoap \
                jsoncpp \
                libev \
                libffi \
                libgsasl \
                libhx \
                libical \
                libxslt \
                mariadb-client \
                mariadb-connector-c \
                libldap \
                libldapcpp \
                libproc \
                openssl \
                perl-app-cpanminus \
                perl-digest-sha1 \
                perl-digest-hmac \
                perl-ntlm \
                perl-html-tagset \
                perl-lwp-mediatypes \
                perl-encode-locale \
                perl-http-date \
                perl-uri \
                perl-io-html \
                perl-http-message \
                perl-html-parser \
                perl-cgi \
                perl-crypt-openssl-random \
                perl-crypt-openssl-guess \
                perl-crypt-openssl-rsa \
                perl-data-uniqid \
                perl-digest-md5 \
                perl-exporter-tiny \
                perl-list-moreutils-xs \
                perl-list-moreutils \
                perl-module-runtime \
                perl-dist-checkconflicts \
                perl-file-copy-recursive \
                perl-file-tail \
                perl-socket6 \
                perl-io-socket-inet6 \
                perl-net-libidn \
                perl-net-ssleay \
                perl-io-socket-ssl \
                perl-io-tee \
                perl-json \
                perl-mime-base64 \
                perl-carp \
                perl-json-webtoken \
                perl-http-cookies \
                perl-net-http \
                perl-http-daemon \
                perl-file-listing \
                perl-www-robotrules \
                perl-http-negotiate \
                perl-capture-tiny \
                perl-devel-symdump \
                perl-test-pod \
                perl-pod-parser \
                perl-pod-coverage \
                perl-try-tiny \
                perl-libwww \
                perl-parse-recdescent \
                perl-mail-imapclient \
                perl-test-taint \
                perl-module-implementation \
                perl-package-stash \
                perl-readonly \
                perl-regexp-common \
                perl-sys-meminfo \
                perl-term-readkey \
                perl-unicode-string \
                poppler \
                procps \
                py3-daemon \
                py3-dateutil \
                py3-dnspython \
                py3-flask \
                py3-lockfile \
                py3-magic \
                py3-minimock \
                py3-nose \
                py3-openssl \
                py3-sleekxmpp \
                py3-soappy \
                py3-tabulate \
                py3-tlslite-ng \
                py3-tzlocal \
                python3 \
                swig \
                w3m \
                xapian-bindings-php7 \
                xapian-bindings-python3 \
                xorgproto \
                ### Add more
                py3-decorator \
                py3-jwt \
                py3-asn1 \
                py3-six \
                py3-validators \
                py3-mimeparse \
                ## Other RunDeps
                bc \
                fail2ban \
                iptables \
                inotify-tools \
                man-db \
                sqlite \
                tidyhtml \
                ## KDAV Hack
                apache2 \
                php7-apache2 \
                && \
    \
    ### Install Python Dependencies
    pip install bjoern && \
    pip install bsddb3 && \
    pip install inotify && \
    pip install falcon && \
    pip install pyJWT && \
    \
    ### Fetch Compass (Kopano Webapp)
    gem install compass && \
    \
    ### Build VMime
    git clone ${VMIME_REPO_URL} /usr/src/vmime && \
    cd /usr/src/vmime && \
    git checkout ${VMIME_VERSION} && \
    #sed -i 's/SET(VMIME_PACKAGE_VERSION	  $VMIME_VERSION))/SET(VMIME_PACKAGE_VERSION	  ${VMIME_VERSION}K1)/g' CMakeLists.txt && \
    cmake $_nolibdirname \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DLIB_INSTALL_DIR=/usr/lib/ \
		-DCMAKE_BUILD_TYPE=None \
        && \
    \
    make -j $(nproc) && \
    make install && \
    \
    ### Build LibS3
    git clone ${LIBS3_REPO_URL} /usr/src/libs3 && \
    cd /usr/src/libs3 && \
    make -j$(nproc) && \
    make DESTDIR=/usr install && \
    \
    ### Build libkcoidc
    git clone ${KOPANO_KCOIDC_REPO_URL} /usr/src/libkcoidc && \
    cd /usr/src/libkcoidc && \
    git checkout ${KOPANO_KCOIDC_VERSION} && \
    autoreconf -fiv && \
    ./configure \
                --prefix /usr \
                && \
    make -j $(nproc) all && \
    make install all && \
    #PYTHON="$(which python3)" make python && \
    echo "Kopano kcOIDC ${KOPANO_KCOIDC_VERSION} built from ${KOPANO_KCOIDC_REPO_URL} on $(date)" > /.tiredofit/kopano-kcoidc.version && \
    echo "Commit: $(cd /usr/src/libkcoidc ; echo $(git rev-parse HEAD))" >> /.tiredofit/kopano-kcoidc.version && \
    \
    ### Build Kopano Core
    git clone ${KOPANO_CORE_REPO_URL} /usr/src/kopano-core && \
    cd /usr/src/kopano-core && \
    git checkout ${KOPANO_CORE_VERSION} && \
    \
    if [ -d "/build-assets/kopano-core/src" ] ; then cp -R /build-assets/src/* /usr/src/kopano-core ; fi; \
    if [ -d "/build-assets/kopano-core/patches" ] ; then for patch in /build-assets/kopano-core/patches/*.patch; do echo "** Applying $patch"; patch -p1 < $patch; done && \ ; fi ; \
    if [ -d "/build-assets/kopano-core/scripts" ] ; then for script in /build-assets/kopano-core/scripts/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    \
    cd /usr/src/kopano-core && \
    autoreconf -fiv && \
    PYTHON=/usr/bin/python3 CPPFLAGS="$CPPFLAGS -fPIC -fPIE -g3 -O0 -Wall -Wextra -Wunused-macros" CFLAGS="$CFLAGS -O0 -g3 -Wall -Wextra" ./configure \
        --prefix=/usr \
        --localstatedir=/var \
        --sysconfdir=/etc \
        --exec-prefix=/usr \
        --sbindir=/usr/bin \
        --datarootdir=/usr/share \
        --includedir=/usr/include \
        --enable-release \
        --enable-epoll \
        --enable-python \
        --enable-kcoidc \
        --disable-static \
        --with-quotatemplate-prefix=/etc/kopano/quotamail \
        --with-searchscripts-prefix=/etc/kopano/searchscripts \
        --with-php=7 \
        && \
    \
    make -j$(nproc) && \
    make install && \
    \
    echo "Kopano Core ${KOPANO_CORE_VERSION} built from ${KOPANO_CORE_REPO_URL} on $(date)" > /.tiredofit/kopano-core.version && \
    echo "Commit: $(cd /usr/src/kopano-core ; echo $(git rev-parse HEAD))" >> /.tiredofit/kopano-core.version && \
    env | grep KOPANO | sed "/KOPANO_KCOIDC/d" | sed "/KOPANO_WEBAPP/d" | sort >> /.tiredofit/kopano-core.version && \
    \
    #### Kopano Webapp
    ### Fetch Source
    git clone ${KOPANO_WEBAPP_REPO_URL} /usr/src/kopano-webapp && \
    cd /usr/src/kopano-webapp && \
    git checkout ${KOPANO_WEBAPP_VERSION} && \
    \
    if [ -d "/build-assets/kopano-webapp/src" ] ; then cp -R /build-assets/src/* /usr/src/kopano-webapp ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts" ] ; then for script in /build-assets/kopano-webapp/scripts/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    \
    # Polish Translation is throwin errors, so we remove for time being
    #rm -rf /usr/src/kopano-webapp/server/language/pl_PL* && \
    #
    \
    ### Build
    cd /usr/src/kopano-webapp && \
    ant deploy && \
    ant deploy-plugins && \
    make all && \
    \
    ### Setup Filesystem
    mkdir -p /usr/share/kopano-webapp && \
    mkdir -p /assets/kopano/config/webapp && \
    mkdir -p /assets/kopano/plugins/webapp && \
    \
    ### Build Plugins
    ## Files
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_REPO_URL} /usr/src/kopano-webapp/plugins/files && \
    cd /usr/src/kopano-webapp/plugins/files && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_VERSION} && \
    if [ -d "/build-assets/kopano-webapp/plugins/files" ] ; then cp -R /build-assets/kopano-webapp/plugins/files/* /usr/src/kopano-webapp/plugins/files/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-files" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-files/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/files/config.php /assets/kopano/config/webapp/config-files.php && \
    ln -sf /etc/kopano/webapp/config-files.php /usr/src/kopano-webapp/deploy/plugins/files/config.php && \
    \
    ## Files Backend: Owncloud
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendOwncloud && \
    cd /usr/src/kopano-webapp/plugins/filesbackendOwncloud && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_OWNCLOUD_VERSION} && \
    if [ -d "/build-assets/kopano-webapp/plugins/filesbackendOwncloud" ] ; then cp -R /build-assets/kopano-webapp/plugins/filesbackendOwncloud/* /usr/src/kopano-webapp/plugins/filesbackendOwncloud/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-filesbackendOwncloud" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-filesbackendOwncloud/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## Files Backend: SeaFile
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendSeafile && \
    cd /usr/src/kopano-webapp/plugins/filesbackendSeafile && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_SEAFILE_VERSION} && \
    if [ -d "/build-assets/kopano-webapp/plugins/filesbackendSeafile" ] ; then cp -R /build-assets/kopano-webapp/plugins/filesbackendSeafile/* /usr/src/kopano-webapp/plugins/filesbackendSeafile/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-filesbackendSeafile" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-filesbackendSeafile/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    cp -R php src && \
    make && \
    make deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/filesbackendSeafile/config.php /assets/kopano/config/webapp/config-files-backend-seafile.php && \
    ln -sf /etc/kopano/webapp/config-files-backend-seafile.php /usr/src/kopano-webapp/deploy/plugins/filesbackendSeafile/config.php && \
    \
    ## Files Backend: SMB
    git clone ${KOPANO_WEBAPP_PLUGIN_FILES_SMB_REPO_URL} /usr/src/kopano-webapp/plugins/filesbackendSMB && \
    cd /usr/src/kopano-webapp/plugins/filesbackendSMB && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_FILES_SMB_VERSION} && \
    if [ -d "/build-assets/kopano-webapp/plugins/filesbackendSMB" ] ; then cp -R /build-assets/kopano-webapp/plugins/filesbackendSMB/* /usr/src/kopano-webapp/plugins/filesbackendSMB/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-filesbackendSMB" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-filesbackendSMB/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## HTML Editor: Minimal
    git clone ${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_MINIMALTINY_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny && \
    if [ -d "/build-assets/kopano-webapp/plugins/htmleditor-minimaltiny" ] ; then cp -R /build-assets/kopano-webapp/plugins/htmleditor-minimaltiny/* /usr/src/kopano-webapp/plugins/htmleditor-minimaltiny/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-htmleditorminimaltiny" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-htmleditorminimaltiny/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## HTML Editor: Jodit
    git clone ${KOPANO_WEBAPP_PLUGIN_JODIT_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-jodit && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-jodit && \
    if [ -d "/build-assets/kopano-webapp/plugins/htmleditor-jodit" ] ; then cp -R /build-assets/kopano-webapp/plugins/htmleditor-jodit/* /usr/src/kopano-webapp/plugins/htmleditor-jodit/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-jodit" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-jodit/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## HTML Editor: Quill
    git clone ${KOPANO_WEBAPP_PLUGIN_HTMLEDITOR_QUILL_REPO_URL} /usr/src/kopano-webapp/plugins/htmleditor-quill && \
    cd /usr/src/kopano-webapp/plugins/htmleditor-quill && \
    if [ -d "/build-assets/kopano-webapp/plugins/htmleditor-quill" ] ; then cp -R /build-assets/kopano-webapp/plugins/htmleditor-quill/* /usr/src/kopano-webapp/plugins/htmleditor-quill/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-quill" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-quill/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    \
    ## Intranet
    git clone ${KOPANO_WEBAPP_PLUGIN_INTRANET_REPO_URL} /usr/src/kopano-webapp/plugins/intranet && \
    cd /usr/src/kopano-webapp/plugins/intranet && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_INTRANET_VERSION} && \
    if [ -d "/build-assets/kopano-webapp/plugins/intranet" ] ; then cp -R /build-assets/kopano-webapp/plugins/intranet/* /usr/src/kopano-webapp/plugins/intranet/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-intranet" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-intranet/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/intranet/config.php /assets/kopano/config/webapp/config-intranet.php && \
    ln -sf /etc/kopano/webapp/config-intranet.php /usr/src/kopano-webapp/deploy/plugins/intranet/config.php && \
    \
    ## Mobile Device Management
    git clone ${KOPANO_WEBAPP_PLUGIN_MDM_REPO_URL} /usr/src/kopano-webapp/plugins/mdm && \
    cd /usr/src/kopano-webapp/plugins/mdm && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_MDM_VERSION} && \
    if [ -d "/build-assets/kopano-webapp/plugins/mdm" ] ; then cp -R /build-assets/kopano-webapp/plugins/mdm/* /usr/src/kopano-webapp/plugins/mdm/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-mdm" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-mdm/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/mdm/config.php /assets/kopano/config/webapp/config-mdm.php && \
    ln -sf /etc/kopano/webapp/config-mdm.php /usr/src/kopano-webapp/deploy/plugins/mdm/config.php && \
    \
    ## Mattermost
    git clone ${KOPANO_WEBAPP_PLUGIN_MATTERMOST_REPO_URL} /usr/src/kopano-webapp/plugins/mattermost && \
    cd /usr/src/kopano-webapp/plugins/mattermost && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_MATTERMOST_VERSION} && \
    if [ -d "/build-assets/kopano-webapp/plugins/mattermost" ] ; then cp -R /build-assets/kopano-webapp/plugins/mattermost/* /usr/src/kopano-webapp/plugins/mattermost/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-mattermost" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-mattermost/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/mattermost/config.php /assets/kopano/config/webapp/config-mattermost.php && \
    ln -sf /etc/kopano/webapp/config-mattermost.php /usr/src/kopano-webapp/deploy/plugins/mattermost/config.php && \
    \
    ## Rocketchat
    cd /usr/src/ && \
    curl -o /usr/src/rocketchat.zip "${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_REPO_URL}" && \
    unzip -d . rocketchat.zip && \
    cd Rocket.Chat && \
    ar x kopano-rocketchat-${KOPANO_WEBAPP_PLUGIN_ROCKETCHAT_VERSION}.deb && \
    tar xvfJ data.tar.xz && \
    cp etc/kopano/webapp/config-rchat.php /assets/kopano/config/webapp/config-rchat.php && \
    cp -R usr/share/kopano-webapp/plugins/rchat /usr/src/kopano-webapp/deploy/plugins/ && \
    ln -sf /etc/kopano/webapp/config-rchat.php /usr/src/kopano-webapp/deploy/plugins/rchat/config.php && \
    if [ -d "/build-assets/kopano-webapp/plugins/rocketchat" ] ; then cp -R /build-assets/kopano-webapp/plugins/rocketchat/* /usr/src/kopano-webapp/deploy/plugins/rchat/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-rocketchat" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-rocketchat/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    \
    ## S/MIME
    git clone ${KOPANO_WEBAPP_PLUGIN_SMIME_REPO_URL} /usr/src/kopano-webapp/plugins/smime && \
    cd /usr/src/kopano-webapp/plugins/smime && \
    git checkout ${KOPANO_WEBAPP_PLUGIN_SMIME_VERSION} && \
    if [ -d "/build-assets/kopano-webapp/plugins/smime" ] ; then cp -R /build-assets/kopano-webapp/plugins/smime/* /usr/src/kopano-webapp/plugins/smime/ ; fi; \
    if [ -d "/build-assets/kopano-webapp/scripts/plugin-smime" ] ; then for script in /build-assets/kopano-webapp/scripts/plugin-smime/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    ant deploy && \
    cp /usr/src/kopano-webapp/deploy/plugins/smime/config.php /assets/kopano/config/webapp/config-smime.php && \
    ln -sf /etc/kopano/webapp/config-smime.php /usr/src/kopano-webapp/deploy/plugins/smime/config.php && \
    \
    ### Move files to Final place
    cp -R /usr/src/kopano-webapp/deploy/* /usr/share/kopano-webapp/ && \
    cd /usr/share/kopano-webapp/ && \
    mv *.dist /assets/kopano/config/webapp && \
    ln -sf /etc/kopano/webapp/config.php config.php && \
    mv plugins/* /assets/kopano/plugins/webapp/ && \
    cp /assets/kopano/plugins/webapp/contactfax/config.php /assets/kopano/config/webapp/contactfax.php && \
    ln -sf /etc/kopano/webapp/config-contactfax.php /assets/kopano/plugins/webapp/contactfax/config.php && \
    cp /assets/kopano/plugins/webapp/gmaps/config.php /assets/kopano/config/webapp/gmaps.php && \
    ln -sf /etc/kopano/webapp/config-gmaps.php /assets/kopano/plugins/webapp/gmaps/config.php && \
    cp /assets/kopano/plugins/webapp/pimfolder/config.php /assets/kopano/config/webapp/pimfolder.php && \
    ln -sf /etc/kopano/webapp/config-pimfolder.php /assets/kopano/plugins/webapp/pimfolder/config.php && \
    \
    echo "Kopano Webapp ${KOPANO_WEBAPP_VERSION} built from ${KOPANO_WEBAPP_REPO_URL} on $(date)" > /.tiredofit/kopano-webapp.version && \
    echo "Commit: $(cd /usr/src/kopano-webapp ; echo $(git rev-parse HEAD))" >> /.tiredofit/kopano-webapp.version && \
    env | grep KOPANO_WEBAPP | sort >> /.tiredofit/kopano-webapp.version && \
    \
    ### KDAV Install
    ### Temporary Hack for KDAV - Using Apache along side of Nginx is not what I want to do, but see issues
    ### posted at https://forum.kopano.io/topic/3433/kdav-with-nginx
    rm -rf /etc/apache2/sites-enabled/* && \
    sed -i "s|^Listen 80|Listen 8888|g" /etc/apache2/httpd.conf && \
    sed -i "s|#LoadModule rewrite_module modules/mod_rewrite.so|LoadModule rewrite_module modules/mod_rewrite.so|g" /etc/apache2/httpd.conf && \
    sed -i "s|#User apache|User nginx|g" /etc/apache2/httpd.conf && \
    sed -i "s|#User apache|User www-data|g" /etc/apache2/httpd.conf && \
    ##########
    \
    git clone -b ${KOPANO_KDAV_VERSION} https://github.com/Kopano-dev/kdav /usr/share/kdav && \
    cd /usr/share/kdav && \
    composer install && \
    \
    ### Z-Push Install
    mkdir /usr/share/zpush && \
    curl -sSL https://github.com/Z-Hub/Z-Push/archive/${Z_PUSH_VERSION}.tar.gz | tar xvfz - --strip 1 -C /usr/share/zpush && \
    ln -s /usr/share/z-push/src/z-push-admin.php /usr/sbin/z-push-admin && \
    ln -s /usr/share/z-push/src/z-push-top.php /usr/sbin/z-push-top && \
    \
    ### Miscellanious tools and scripts
    mkdir -p /assets/kopano/tools && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/Core-tools.git /assets/kopano/tools/core-tools && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/lab-scripts.git /assets/kopano/tools/lab-scripts && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/mail-migrations.git /assets/kopano/tools/mail-migrations && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/support.git /assets/kopano/tools/support && \
    git clone --depth 1 https://stash.kopano.io/scm/ksc/webapp-tools.git /assets/kopano/tools/webapp-tools && \
    find /assets/kopano/tools -name '*.py' -exec chmod +x {} \; && \
    \
    ##### Configuration of Filesystem and moving things around
    mkdir -p /assets/kopano/config && \
    ### Copy Default KDAV Configuration
    mkdir -p /assets/kdav/config/ && \
    cp -R /usr/share/kdav/config.php /assets/kdav/config/ && \
    ### Copy Default ZPush Configuration
    mkdir -p /assets/zpush/config && \
    cp -R /usr/share/zpush/src/config.php /assets/zpush/config/ && \
    cp -R /usr/share/zpush/src/autodiscover/config.php /assets/zpush/config/config-autodiscover.php && \
    cp -R /usr/share/zpush/tools/gab2contacts/config.php /assets/zpush/config/config-gab2contacts.php && \
    cp -R /usr/share/zpush/tools/gab-sync/config.php /assets/zpush/config/config-gab-sync.php && \
    mkdir -p /assets/zpush/config/backend && \
    mkdir -p /assets/zpush/config/backend/ipcmemcached && \
    cp -R /usr/share/zpush//src/backend/ipcmemcached/config.php /assets/zpush/config/backend/ipcmemcached/ && \
    mkdir -p /assets/zpush/config/backend/kopano && \
    cp -R /usr/share/zpush/src/backend/kopano/config.php /assets/zpush/config/backend/kopano/ && \
    mkdir -p /assets/zpush/config/backend/sqlstatemachine && \
    cp -R /usr/share/zpush/src/backend/sqlstatemachine/config.php /assets/zpush/config/backend/sqlstatemachine/ && \
    ### Move everything in /etc/kopano to spots under /assets
    cp -R /etc/kopano/* /assets/kopano/config/ && \
    mkdir -p /assets/kopano/templates && \
    cp -R /etc/kopano/quotamail/* /assets/kopano/templates && \
    rm -rf /etc/kopano/quotamail && \
    mkdir -p /assets/kopano/scripts && \
    cp -R /etc/kopano/userscripts /assets/kopano/scripts/ && \
    cp -R /usr/lib/kopano/userscripts/* /assets/kopano/scripts/userscripts && \
    cp -R /etc/kopano/searchscripts /assets/kopano/scripts && \
    rm -rf /etc/kopano && \
    ln -sf /config /etc/kopano && \
    ### Setup shortcuts to some tools
    ln -s /assets/kopano/tools/core-tools/store-stats/store-stats.py /usr/sbin/store-stats && \
    ln -s /assets/kopano/tools/webapp-tools/files_admin/files_admin.py /usr/sbin/files-admin && \
    ln -s /assets/kopano/tools/webapp-tools/webapp_admin/webapp_admin.py /usr/sbin/webapp-admin && \
    ### Setup some core directories
    mkdir -p /var/run/kopano && \
    mkdir -p /var/run/kopano-search && \
    chown -R kopano /var/run/kopano && \
    chown -R kopano /var/run/kopano-search && \
    #### This ideally could be fixed in source code but here's a hack
    ln -s /usr/bin/kopano-autorespond /usr/sbin/kopano-autorespond && \
    ### Container Override
    if [ -d "/build-assets/container/src/" ] ; then cp -R /build-assets/runtime/src/* / ; fi; \
    if [ -d "/build-assets/container/scripts" ] ; then for script in /build-assets/container/scripts/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    #rm -rf /build-assets/ && \
    ### Fix some issues found by community
    sed -i "s|\"server_ssl\": ssl,|\"server_ssl\": (ssl.lower() == 'true'),|g" /assets/kopano/tools/webapp-tools/files_admin/files_admin.py && \
    \
    ### Final permissions reset
    chown -R nginx:www-data /assets/kopano/plugins/webapp && \
    chown -R nginx:www-data /usr/share/kopano-webapp && \
    chown -R nginx:www-data /usr/share/kdav && \
    \
    ### Cleanup
    apk del .build-deps && \
    rm -rf /usr/src/* /var/cache/apk/* && \
    rm -rf /root/.cache /root/.composer /root/.config /root/.gem /root/.npm /root/go && \
    rm -rf /etc/logrotate.d/{acpid,apache2,php-fpm7} && \
    cd /etc/fail2ban && \
    rm -rf fail2ban.conf fail2ban.d jail.conf jail.d paths-*.conf

### Assets Install
ADD install /
